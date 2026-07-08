import SwiftUI
import AVFoundation

struct MeasurementResultView: View {
    let result: JumpAnalysisResult
    let videoURL: URL
    let onSaved: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var takeoffThumbnail: CGImage?
    @State private var landingThumbnail: CGImage?
    @State private var isSaving = false

    var body: some View {
        ZStack {
            Color.ink.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Spacer()

                VStack(spacing: Spacing.xxs) {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                        Text(String(format: "%.1f", result.heightInches))
                            .font(VertFont.heroNumber)
                            .foregroundStyle(.voltGreen)
                        Text("in")
                            .font(VertFont.title)
                            .foregroundStyle(.textMuted)
                    }
                    Text(result.jumpType == .standing ? "Standing Vert" : "Approach Jump")
                        .font(VertFont.bodyText)
                        .foregroundStyle(.textMuted)
                }

                credibilityBadge

                frameEvidence

                Spacer()

                VStack(spacing: Spacing.sm) {
                    Button {
                        Task { await save() }
                    } label: {
                        HStack {
                            if isSaving { ProgressView().tint(.ink) }
                            Text(isSaving ? "Saving…" : "Save Measurement")
                                .font(VertFont.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.voltGreen)
                    .foregroundStyle(.ink)
                    .disabled(isSaving)
                }
            }
            .padding(Spacing.lg)
        }
        .task { await loadThumbnails() }
        .navigationBarBackButtonHidden(true)
    }

    private var credibilityBadge: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.voltGreen)
            Text("Verified by Video")
                .font(VertFont.caption)
                .foregroundStyle(.textPrimary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(Color.surface)
        .clipShape(Capsule())
    }

    private var frameEvidence: some View {
        HStack(spacing: Spacing.md) {
            frameCard(title: "Takeoff", image: takeoffThumbnail)
            frameCard(title: "Landing", image: landingThumbnail)
        }
    }

    private func frameCard(title: String, image: CGImage?) -> some View {
        VStack(spacing: Spacing.xxs) {
            Group {
                if let image {
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.surface
                }
            }
            .frame(width: 120, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm)
                    .strokeBorder(Color.voltGreen.opacity(0.5), lineWidth: 1.5)
            )
            Text(title)
                .font(VertFont.caption)
                .foregroundStyle(.textMuted)
        }
    }

    private func loadThumbnails() async {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: videoURL))
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        takeoffThumbnail = try? await generator.image(at: result.timestamp(forFrame: result.takeoffFrameIndex)).image
        landingThumbnail = try? await generator.image(at: result.timestamp(forFrame: result.landingFrameIndex)).image
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let filename = "\(UUID().uuidString).mov"
        let destination = PersistenceController.videosDirectory.appendingPathComponent(filename)
        try? FileManager.default.copyItem(at: videoURL, to: destination)

        let measurement = JumpMeasurement(
            jumpType: result.jumpType,
            heightInches: result.heightInches,
            source: .cameraFlightTime,
            videoFilename: filename,
            takeoffFrameIndex: result.takeoffFrameIndex,
            landingFrameIndex: result.landingFrameIndex,
            frameRate: result.frameRate
        )
        modelContext.insert(measurement)
        try? modelContext.save()

        onSaved()
    }
}
