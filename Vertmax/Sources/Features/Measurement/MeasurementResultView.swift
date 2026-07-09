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
    @State private var revealed = false
    @State private var shareCardImage: Image?
    @State private var shareCardURL: URL?

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
                            .font(VertFont.heroUnit)
                            .foregroundStyle(.textMuted)
                    }
                    Text(result.jumpType == .standing ? "Standing Vert" : "Approach Jump")
                        .font(VertFont.bodyText)
                        .foregroundStyle(.textMuted)
                }
                .padding(.vertical, Spacing.lg)
                .background {
                    Circle()
                        .fill(RadialGradient.voltGlow)
                        .frame(width: 320, height: 320)
                        .allowsHitTesting(false)
                }
                .trajectoryBackdrop(opacity: 0.18)
                .scaleEffect(revealed ? 1 : 0.72)
                .opacity(revealed ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.68), value: revealed)

                CredibilityBadge()
                    .reveal(revealed, delay: 0.2)

                frameEvidence
                    .reveal(revealed, delay: 0.28)

                Spacer()

                VStack(spacing: Spacing.sm) {
                    Button {
                        Task { await save() }
                    } label: {
                        HStack {
                            if isSaving { ProgressView().tint(.ink) }
                            Text(isSaving ? "Saving…" : "Save Measurement")
                        }
                    }
                    .buttonStyle(VoltButtonStyle())
                    .disabled(isSaving)
                }
                .reveal(revealed, delay: 0.34)
            }
            .padding(Spacing.lg)
        }
        .task {
            await loadThumbnails()
            renderShareCard()
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            revealed = true
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let shareCardURL {
                    ShareLink(
                        item: shareCardURL,
                        preview: SharePreview("My Vertmax Jump", image: shareCardImage ?? Image(systemName: "photo"))
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.textPrimary)
                    }
                    .accessibilityLabel("Share")
                }
            }
        }
    }

    private var frameEvidence: some View {
        HStack(spacing: Spacing.md) {
            FrameThumbnail(image: takeoffThumbnail, label: "Takeoff")
            FrameThumbnail(image: landingThumbnail, label: "Landing")
        }
    }

    /// Renders `ShareCardView` off-screen to a PNG file so `ShareLink` has a
    /// stable `Transferable` `URL` to hand off — more reliable across share
    /// destinations (Messages, Instagram, AirDrop) than an in-memory image.
    private func renderShareCard() {
        let card = ShareCardView(
            heightInches: result.heightInches,
            jumpTypeLabel: result.jumpType == .standing ? "Standing Vert" : "Approach Jump",
            date: .now,
            takeoffImage: takeoffThumbnail,
            landingImage: landingThumbnail
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        guard let uiImage = renderer.uiImage, let data = uiImage.pngData() else { return }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("vertmax-vert-\(UUID().uuidString).png")
        do {
            try data.write(to: url)
            // Only publish once the file actually exists on disk — otherwise
            // ShareLink would hand the OS a URL to nothing and sharing would
            // silently fail with no feedback to the user.
            shareCardImage = Image(uiImage: uiImage)
            shareCardURL = url
        } catch {
            shareCardImage = nil
            shareCardURL = nil
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
        WidgetSnapshotRefresher.refresh(context: modelContext)
        SyncEngine.push(measurement: measurement)

        onSaved()
    }
}
