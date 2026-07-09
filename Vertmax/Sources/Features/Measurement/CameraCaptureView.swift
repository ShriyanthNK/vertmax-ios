import SwiftUI

struct CameraCaptureView: View {
    let jumpType: JumpType
    let onFinished: (URL) -> Void
    let onCancel: () -> Void

    @StateObject private var camera = CameraService()
    @State private var isPreparing = true
    @State private var recordingPulse = false

    var body: some View {
        ZStack {
            Color.ink.ignoresSafeArea()

            if isPreparing {
                ProgressView()
                    .tint(.voltGreen)
            } else {
                CameraPreviewView(cameraService: camera)
                    .ignoresSafeArea()

                framingGuide

                VStack {
                    topBar
                    Spacer()
                    bottomBar
                }
                .padding(Spacing.lg)
            }
        }
        .task {
            await camera.requestPermissionsAndConfigure()
            isPreparing = false
        }
        .onDisappear { camera.stopSession() }
        .alert(
            "Camera Error",
            isPresented: .constant(camera.lastError != nil),
            presenting: camera.lastError
        ) { _ in
            Button("OK") { onCancel() }
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.textPrimary)
                    .padding(Spacing.sm)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Cancel")
            Spacer()
            if camera.activeFrameRate > 0 {
                Text("\(Int(camera.activeFrameRate)) FPS")
                    .font(VertFont.caption)
                    .foregroundStyle(.ink)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color.voltGreen)
                    .clipShape(Capsule())
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: Spacing.sm) {
            Text(camera.isRecording ? "Recording, jump now" : "Frame yourself fully in the guide, then record")
                .font(VertFont.caption)
                .foregroundStyle(.textPrimary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(.ultraThinMaterial, in: Capsule())

            Button {
                Task { await toggleRecording() }
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(camera.isRecording ? Color.stopRed : Color.voltGreen, lineWidth: 4)
                        .frame(width: 76, height: 76)
                        .scaleEffect(camera.isRecording && recordingPulse ? 1.12 : 1)
                        .opacity(camera.isRecording && recordingPulse ? 0.4 : 1)
                        .animation(camera.isRecording ? .easeOut(duration: 0.9).repeatForever(autoreverses: false) : .default, value: recordingPulse)
                    Circle()
                        .fill(camera.isRecording ? Color.stopRed : Color.voltGreen)
                        .frame(width: camera.isRecording ? 32 : 62, height: camera.isRecording ? 32 : 62)
                        .animation(.easeInOut(duration: 0.15), value: camera.isRecording)
                }
            }
            .accessibilityLabel(camera.isRecording ? "Stop recording" : "Start recording")
            .onChange(of: camera.isRecording) { _, isRecording in
                recordingPulse = isRecording
            }
        }
    }

    /// Vertical guide box: frames the jumper full-body so takeoff/landing are
    /// always in view, regardless of tripod distance.
    private var framingGuide: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: Radius.md)
                .strokeBorder(Color.voltGreen.opacity(0.6), lineWidth: 2, antialiased: true)
                .frame(width: geo.size.width * 0.6, height: geo.size.height * 0.75)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .allowsHitTesting(false)
    }

    private func toggleRecording() async {
        if camera.isRecording {
            camera.stopRecording()
        } else {
            do {
                let url = try await camera.startRecording()
                onFinished(url)
            } catch {
                camera.lastError = .configurationFailed
            }
        }
    }
}
