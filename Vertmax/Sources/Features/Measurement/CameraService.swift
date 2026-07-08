import AVFoundation
import Combine

enum CameraServiceError: LocalizedError {
    case permissionDenied
    case deviceUnavailable
    case configurationFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera access is required to measure your jump. Enable it in Settings."
        case .deviceUnavailable:
            return "No usable camera was found on this device."
        case .configurationFailed:
            return "Couldn't configure the camera for high-frame-rate recording."
        }
    }
}

/// Configures the back camera for the highest available frame rate (target
/// 120fps+, 60fps minimum per PRD §5.2) and records to a temp file.
///
/// `@unchecked Sendable`: AVCaptureSession/output access is confined to
/// `sessionQueue`, and `@Published` mutations are always dispatched to main —
/// both enforced by hand rather than the compiler, which is why this needs
/// the unchecked escape hatch instead of automatic Sendable conformance.
final class CameraService: NSObject, ObservableObject, @unchecked Sendable {
    @Published private(set) var isRecording = false
    @Published private(set) var activeFrameRate: Double = 0
    @Published var lastError: CameraServiceError?

    let session = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var recordingContinuation: CheckedContinuation<URL, Error>?
    private let sessionQueue = DispatchQueue(label: "com.vertmax.camera.session")

    func requestPermissionsAndConfigure() async {
        let cameraGranted = await AVCaptureDevice.requestAccess(for: .video)
        guard cameraGranted else {
            await MainActor.run { lastError = .permissionDenied }
            return
        }
        _ = await AVCaptureDevice.requestAccess(for: .audio)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            sessionQueue.async { [weak self] in
                self?.configureSession()
                continuation.resume()
            }
        }
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            DispatchQueue.main.async { self.lastError = .deviceUnavailable }
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .inputPriority

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.inputs.isEmpty, session.canAddInput(input) {
                session.addInput(input)
            }
            if session.outputs.isEmpty, session.canAddOutput(movieOutput) {
                session.addOutput(movieOutput)
            }

            let chosenFrameRate = try configureHighFrameRate(on: device)
            DispatchQueue.main.async { self.activeFrameRate = chosenFrameRate }
        } catch {
            session.commitConfiguration()
            DispatchQueue.main.async { self.lastError = .configurationFailed }
            return
        }

        session.commitConfiguration()
        session.startRunning()
    }

    /// Picks the highest-frame-rate format available (prefers 240/120fps
    /// slow-mo formats), falling back toward 60fps as the hard floor.
    @discardableResult
    private func configureHighFrameRate(on device: AVCaptureDevice) throws -> Double {
        let candidates = device.formats.compactMap { format -> (AVCaptureDevice.Format, Double)? in
            guard let maxRange = format.videoSupportedFrameRateRanges.max(by: { $0.maxFrameRate < $1.maxFrameRate }) else {
                return nil
            }
            return (format, maxRange.maxFrameRate)
        }

        guard let best = candidates.max(by: { $0.1 < $1.1 }), best.1 >= 60 else {
            throw CameraServiceError.configurationFailed
        }

        try device.lockForConfiguration()
        device.activeFormat = best.0
        let targetFPS = min(best.1, 240)
        let duration = CMTimeMake(value: 1, timescale: Int32(targetFPS))
        device.activeVideoMinFrameDuration = duration
        device.activeVideoMaxFrameDuration = duration
        device.unlockForConfiguration()

        return targetFPS
    }

    func makePreviewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    func startRecording() async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        return try await withCheckedThrowingContinuation { continuation in
            self.recordingContinuation = continuation
            sessionQueue.async { [weak self] in
                guard let self else { return }
                self.movieOutput.startRecording(to: outputURL, recordingDelegate: self)
                DispatchQueue.main.async { self.isRecording = true }
            }
        }
    }

    func stopRecording() {
        sessionQueue.async { [weak self] in
            self?.movieOutput.stopRecording()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }
}

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        DispatchQueue.main.async { self.isRecording = false }
        if let error {
            recordingContinuation?.resume(throwing: error)
        } else {
            recordingContinuation?.resume(returning: outputFileURL)
        }
        recordingContinuation = nil
    }
}
