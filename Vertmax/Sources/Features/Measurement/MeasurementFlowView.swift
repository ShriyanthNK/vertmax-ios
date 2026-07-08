import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

private enum MeasurementStep {
    case chooseType
    case chooseCaptureMethod(JumpType)
    case capture(JumpType)
    case importVideo(JumpType)
    case processing(URL, JumpType)
    case result(JumpAnalysisResult, URL)
    case manualEntry
    indirect case failed(String, retry: MeasurementStep?)
}

/// Orchestrates the measurement flow: pick jump type → record → analyze →
/// show the credible, shareable result (or fall back to manual entry).
struct MeasurementFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var step: MeasurementStep = .chooseType

    var body: some View {
        NavigationStack {
            content
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
                .profileToolbar()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .chooseType:
            JumpTypePickerView(
                onSelect: { step = .chooseCaptureMethod($0) },
                onManualEntry: { step = .manualEntry }
            )

        case .chooseCaptureMethod(let jumpType):
            CaptureMethodPickerView(
                onRecord: { step = .capture(jumpType) },
                onImport: { step = .importVideo(jumpType) },
                onBack: { step = .chooseType }
            )

        case .capture(let jumpType):
            CameraCaptureView(
                jumpType: jumpType,
                onFinished: { url in step = .processing(url, jumpType) },
                onCancel: { step = .chooseType }
            )

        case .importVideo(let jumpType):
            VideoImportView(
                onPicked: { url in step = .processing(url, jumpType) },
                onCancel: { step = .chooseCaptureMethod(jumpType) }
            )

        case .processing(let url, let jumpType):
            MeasurementProcessingView()
                .task {
                    do {
                        let result = try await JumpAnalyzer.analyze(videoURL: url, jumpType: jumpType)
                        step = .result(result, url)
                    } catch {
                        step = .failed(error.localizedDescription, retry: .chooseCaptureMethod(jumpType))
                    }
                }

        case .result(let result, let videoURL):
            MeasurementResultView(result: result, videoURL: videoURL) {
                dismiss()
            }

        case .manualEntry:
            ManualEntryView { dismiss() }

        case .failed(let message, let retry):
            MeasurementErrorView(
                message: message,
                onRetry: retry.map { retryStep in { step = retryStep } },
                onManualEntry: { step = .manualEntry }
            )
        }
    }
}

private struct JumpTypePickerView: View {
    let onSelect: (JumpType) -> Void
    let onManualEntry: () -> Void

    var body: some View {
        ZStack {
            Color.ink.ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                Spacer()
                Text("What kind of jump?")
                    .font(VertFont.title)
                    .foregroundStyle(.textPrimary)

                VStack(spacing: Spacing.sm) {
                    optionButton(title: "Standing Vert", subtitle: "No steps, jump straight up", jumpType: .standing)
                    optionButton(title: "Approach Jump", subtitle: "Run-up before you jump", jumpType: .approach)
                }

                Button("Can't film? Enter manually", action: onManualEntry)
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)
                    .padding(.top, Spacing.sm)

                Spacer()
            }
            .padding(Spacing.lg)
        }
    }

    private func optionButton(title: String, subtitle: String, jumpType: JumpType) -> some View {
        Button {
            onSelect(jumpType)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(VertFont.headline)
                    .foregroundStyle(.textPrimary)
                Text(subtitle)
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
    }
}

private struct CaptureMethodPickerView: View {
    let onRecord: () -> Void
    let onImport: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color.ink.ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                Spacer()
                Text("Record or import?")
                    .font(VertFont.title)
                    .foregroundStyle(.textPrimary)

                VStack(spacing: Spacing.sm) {
                    methodButton(title: "Record Now", subtitle: "Use your camera live", icon: "camera.fill", action: onRecord)
                    methodButton(title: "Choose from Library", subtitle: "Use an existing video (a friend's recording works too)", icon: "square.and.arrow.down", action: onImport)
                }

                Button("Back", action: onBack)
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)
                    .padding(.top, Spacing.sm)

                Spacer()
            }
            .padding(Spacing.lg)
        }
    }

    private func methodButton(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(.voltGreen)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(VertFont.headline)
                        .foregroundStyle(.textPrimary)
                    Text(subtitle)
                        .font(VertFont.caption)
                        .foregroundStyle(.textMuted)
                }
                Spacer()
            }
            .padding(Spacing.md)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
    }
}

/// Copies a picked `PhotosPickerItem` (which only exposes a transient,
/// sandboxed file) into a stable temp URL that `JumpAnalyzer`/`AVAssetReader`
/// can read from repeatedly.
private struct PickedVideo: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { picked in
            SentTransferredFile(picked.url)
        } importing: { received in
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            try FileManager.default.copyItem(at: received.file, to: destination)
            return Self(url: destination)
        }
    }
}

private struct VideoImportView: View {
    let onPicked: (URL) -> Void
    let onCancel: () -> Void

    @State private var selection: PhotosPickerItem?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.ink.ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                Spacer()

                if isLoading {
                    ProgressView().tint(.voltGreen)
                    Text("Loading video…")
                        .font(VertFont.caption)
                        .foregroundStyle(.textMuted)
                } else {
                    PhotosPicker(selection: $selection, matching: .videos) {
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 36))
                                .foregroundStyle(.voltGreen)
                            Text("Choose a Video")
                                .font(VertFont.headline)
                                .foregroundStyle(.textPrimary)
                            Text("Pick a jump video from your photo library")
                                .font(VertFont.caption)
                                .foregroundStyle(.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.xl)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(VertFont.caption)
                            .foregroundStyle(.stopRed)
                    }

                    Button("Back", action: onCancel)
                        .font(VertFont.caption)
                        .foregroundStyle(.textMuted)
                        .padding(.top, Spacing.sm)
                }

                Spacer()
            }
            .padding(Spacing.lg)
        }
        .onChange(of: selection) { _, newValue in
            guard let newValue else { return }
            isLoading = true
            errorMessage = nil
            Task {
                do {
                    if let picked = try await newValue.loadTransferable(type: PickedVideo.self) {
                        onPicked(picked.url)
                    } else {
                        isLoading = false
                        errorMessage = "Couldn't load that video. Try another."
                    }
                } catch {
                    isLoading = false
                    errorMessage = "Couldn't load that video. Try another."
                }
            }
        }
    }
}

private struct MeasurementProcessingView: View {
    var body: some View {
        ZStack {
            Color.ink.ignoresSafeArea()
            VStack(spacing: Spacing.md) {
                ProgressView()
                    .tint(.voltGreen)
                    .scaleEffect(1.4)
                Text("Measuring your jump…")
                    .font(VertFont.headline)
                    .foregroundStyle(.textPrimary)
                Text("Detecting takeoff and landing frames")
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)
            }
        }
    }
}

private struct MeasurementErrorView: View {
    let message: String
    let onRetry: (() -> Void)?
    let onManualEntry: () -> Void

    var body: some View {
        ZStack {
            Color.ink.ignoresSafeArea()
            VStack(spacing: Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.cautionAmber)
                Text(message)
                    .font(VertFont.body(16))
                    .foregroundStyle(.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)

                if let onRetry {
                    Button("Try Again", action: onRetry)
                        .buttonStyle(.borderedProminent)
                        .tint(.voltGreen)
                        .foregroundStyle(.ink)
                }
                Button("Enter Manually Instead", action: onManualEntry)
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)
            }
            .padding(Spacing.lg)
        }
    }
}
