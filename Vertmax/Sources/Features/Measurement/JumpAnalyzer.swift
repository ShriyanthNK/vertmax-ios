import AVFoundation
import Vision
import CoreGraphics

struct JumpAnalysisResult {
    let jumpType: JumpType
    let takeoffFrameIndex: Int
    let landingFrameIndex: Int
    let frameRate: Double
    let heightInches: Double

    var flightTimeSeconds: Double {
        Double(landingFrameIndex - takeoffFrameIndex) / frameRate
    }

    func timestamp(forFrame frameIndex: Int) -> CMTime {
        CMTime(value: CMTimeValue(frameIndex), timescale: CMTimeScale(frameRate))
    }
}

enum JumpAnalysisError: LocalizedError {
    case noVideoTrack
    case personNotDetected
    case jumpNotDetected

    var errorDescription: String? {
        switch self {
        case .noVideoTrack:
            return "That video couldn't be read. Try recording again."
        case .personNotDetected:
            return "Couldn't find a person in the video. Make sure you're fully framed and well-lit."
        case .jumpNotDetected:
            return "Couldn't detect a clear takeoff and landing. Stand still for a moment before you jump, and land in frame."
        }
    }
}

/// Physics-based flight-time measurement (PRD §5.2): tracks ankle height
/// across frames with Vision body pose, finds the last ground-contact frame
/// before takeoff and the first ground-contact frame after landing, then
/// converts flight time to height via h = g·t²/8.
enum JumpAnalyzer {
    private static let gravity = 9.80665 // m/s^2
    private static let metersToInches = 39.3701
    private static let maxAnalyzedFrames = 600 // ~5s at 120fps — a jump attempt is short

    static func analyze(videoURL: URL, jumpType: JumpType) async throws -> JumpAnalysisResult {
        try await Task.detached(priority: .userInitiated) {
            do {
                return try runAnalysis(videoURL: videoURL, jumpType: jumpType)
            } catch JumpAnalysisError.personNotDetected {
                #if targetEnvironment(simulator)
                // VNDetectHumanBodyPoseRequest needs the Neural Engine, which
                // the Simulator doesn't have — every frame silently comes back
                // with zero results no matter what video is picked, so real
                // detection always fails this exact way here. Substitute a
                // plausible result (from the real video's own duration) so the
                // rest of the flow is still testable without a device. Compiled
                // out of every real build — device hardware never takes this path.
                return try simulatedResult(videoURL: videoURL, jumpType: jumpType)
                #else
                throw JumpAnalysisError.personNotDetected
                #endif
            }
        }.value
    }

    #if targetEnvironment(simulator)
    private static func simulatedResult(videoURL: URL, jumpType: JumpType) throws -> JumpAnalysisResult {
        let asset = AVURLAsset(url: videoURL)
        guard let track = asset.tracks(withMediaType: .video).first else {
            throw JumpAnalysisError.noVideoTrack
        }
        let frameRate = Double(track.nominalFrameRate) > 0 ? Double(track.nominalFrameRate) : 60.0

        let durationSeconds = CMTimeGetSeconds(asset.duration)
        let totalFrames = durationSeconds.isFinite && durationSeconds > 0
            ? max(Int(durationSeconds * frameRate), 30)
            : 150

        let heightInches = Double.random(in: 18...34)
        let heightMeters = heightInches / metersToInches
        let flightTime = (8 * heightMeters / gravity).squareRoot()
        let framesApart = max(Int((flightTime * frameRate).rounded()), 2)

        let takeoff = max((totalFrames - framesApart) / 2, 0)
        let landing = min(takeoff + framesApart, totalFrames - 1)

        return JumpAnalysisResult(
            jumpType: jumpType,
            takeoffFrameIndex: takeoff,
            landingFrameIndex: landing,
            frameRate: frameRate,
            heightInches: heightInches
        )
    }
    #endif

    private static func runAnalysis(videoURL: URL, jumpType: JumpType) throws -> JumpAnalysisResult {
        let asset = AVURLAsset(url: videoURL)
        guard let track = asset.tracks(withMediaType: .video).first else {
            throw JumpAnalysisError.noVideoTrack
        }

        let frameRate = Double(track.nominalFrameRate) > 0 ? Double(track.nominalFrameRate) : 60.0
        let orientation = cgOrientation(for: track.preferredTransform)

        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(
            track: track,
            outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        )
        reader.add(output)
        reader.startReading()

        var ankleHeights: [Double?] = []
        var frameCount = 0

        while reader.status == .reading, frameCount < maxAnalyzedFrames {
            guard let sampleBuffer = output.copyNextSampleBuffer(),
                  let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                break
            }
            frameCount += 1

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
            let request = VNDetectHumanBodyPoseRequest()
            try? handler.perform([request])

            ankleHeights.append(extractAnkleHeight(from: request.results?.first))
        }
        reader.cancelReading()

        guard ankleHeights.contains(where: { $0 != nil }) else {
            throw JumpAnalysisError.personNotDetected
        }

        let heights = fillGaps(ankleHeights)
        guard let (takeoff, landing) = detectTakeoffAndLanding(in: heights) else {
            throw JumpAnalysisError.jumpNotDetected
        }

        let flightTime = Double(landing - takeoff) / frameRate
        let heightMeters = gravity * flightTime * flightTime / 8
        let heightInches = heightMeters * metersToInches

        return JumpAnalysisResult(
            jumpType: jumpType,
            takeoffFrameIndex: takeoff,
            landingFrameIndex: landing,
            frameRate: frameRate,
            heightInches: heightInches
        )
    }

    /// Vision's normalized coordinates have origin bottom-left, y increasing
    /// upward — matches "higher off the ground = larger value" directly.
    private static func extractAnkleHeight(from observation: VNHumanBodyPoseObservation?) -> Double? {
        guard let observation, let points = try? observation.recognizedPoints(.all) else { return nil }

        let minConfidence: Float = 0.3
        let ankles = [points[.leftAnkle], points[.rightAnkle]].compactMap { $0 }
            .filter { $0.confidence >= minConfidence }

        if !ankles.isEmpty {
            return ankles.map { Double($0.location.y) }.reduce(0, +) / Double(ankles.count)
        }

        // Fall back to hips if ankles are occluded (e.g. motion blur at peak).
        let hips = [points[.leftHip], points[.rightHip]].compactMap { $0 }
            .filter { $0.confidence >= minConfidence }
        guard !hips.isEmpty else { return nil }
        return hips.map { Double($0.location.y) }.reduce(0, +) / Double(hips.count)
    }

    /// Carries the last known value forward across brief detection gaps so a
    /// missed frame or two doesn't break the takeoff/landing search.
    private static func fillGaps(_ values: [Double?]) -> [Double] {
        var result: [Double] = []
        var last: Double = values.compactMap { $0 }.first ?? 0
        for value in values {
            if let value { last = value }
            result.append(last)
        }
        return result
    }

    private static func detectTakeoffAndLanding(in heights: [Double]) -> (takeoff: Int, landing: Int)? {
        let baselineWindow = min(8, heights.count / 4)
        guard baselineWindow > 0 else { return nil }

        let baseline = heights.prefix(baselineWindow)
        let baselineMean = baseline.reduce(0, +) / Double(baseline.count)
        let variance = baseline.reduce(0) { $0 + ($1 - baselineMean) * ($1 - baselineMean) } / Double(baseline.count)
        let stdDev = variance.squareRoot()
        let threshold = baselineMean + max(3 * stdDev, 0.015)

        // Rising edge: last on-ground frame immediately before a sustained rise.
        var takeoffIndex: Int?
        var i = baselineWindow
        while i < heights.count - 2 {
            if heights[i] > threshold, heights[i + 1] > threshold, heights[i + 2] > threshold {
                takeoffIndex = i - 1
                break
            }
            i += 1
        }
        guard let takeoff = takeoffIndex, takeoff >= 0 else { return nil }

        // Peak, then search forward for the first frame back at ground level.
        guard let peakIndex = heights[takeoff...].indices.max(by: { heights[$0] < heights[$1] }) else {
            return nil
        }

        var landingIndex: Int?
        var j = peakIndex
        while j < heights.count {
            if heights[j] <= threshold {
                landingIndex = j
                break
            }
            j += 1
        }
        guard let landing = landingIndex, landing > takeoff else { return nil }

        return (takeoff, landing)
    }

    /// Buckets the transform's rotation angle into the nearest 90° instead of
    /// matching exact matrix values — videos that pass through a transfer/
    /// edit pipeline (AirDrop, Photos trim, re-encode) often keep the same
    /// rotation but pick up a non-unity scale, which an exact-value switch
    /// would silently miss and fall back to `.up`, feeding Vision a sideways
    /// frame on every single frame (the likely cause of "no person found" on
    /// an otherwise clean video).
    private static func cgOrientation(for transform: CGAffineTransform) -> CGImagePropertyOrientation {
        let degrees = atan2(transform.b, transform.a) * 180 / .pi
        switch degrees {
        case -45..<45: return .up
        case 45..<135: return .right
        case -135..<(-45): return .left
        default: return .down
        }
    }
}
