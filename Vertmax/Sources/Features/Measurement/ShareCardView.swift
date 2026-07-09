import SwiftUI

/// Fixed-size branded graphic for sharing a measurement outside the app —
/// Messages, Instagram Stories, AirDrop. Built at a constant point size
/// (not tied to the device screen) so the export looks the same everywhere;
/// `ImageRenderer` captures it at high scale for a crisp result. Reuses the
/// same visual language as the in-app result screen (mono readout, volt
/// glow, trajectory arc) so a shared card is recognizably a Vertmax card.
struct ShareCardView: View {
    let heightInches: Double
    let jumpTypeLabel: String
    let date: Date
    var takeoffImage: CGImage?
    var landingImage: CGImage?

    private let cardSize = CGSize(width: 400, height: 700)

    var body: some View {
        ZStack {
            Color.ink

            VStack(spacing: Spacing.xl) {
                HStack(spacing: Spacing.xs) {
                    VertmaxLogoMark()
                        .frame(width: 22, height: 22)
                    Text("VERTMAX")
                        .font(VertFont.wordmark)
                        .foregroundStyle(.textPrimary)
                        .eyebrowTracking()
                    Spacer()
                }

                Spacer()

                VStack(spacing: Spacing.xxs) {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                        Text(String(format: "%.1f", heightInches))
                            .font(VertFont.heroNumber)
                            .foregroundStyle(.voltGreen)
                        Text("in")
                            .font(VertFont.heroUnit)
                            .foregroundStyle(.textMuted)
                    }
                    Text(jumpTypeLabel)
                        .font(VertFont.bodyText)
                        .foregroundStyle(.textMuted)
                }
                .padding(.vertical, Spacing.lg)
                .background {
                    Circle()
                        .fill(RadialGradient.voltGlow)
                        .frame(width: 320, height: 320)
                }
                .trajectoryBackdrop(opacity: 0.18)

                CredibilityBadge()

                if takeoffImage != nil || landingImage != nil {
                    HStack(spacing: Spacing.md) {
                        FrameThumbnail(image: takeoffImage, size: CGSize(width: 100, height: 130))
                        FrameThumbnail(image: landingImage, size: CGSize(width: 100, height: 130))
                    }
                }

                Spacer()

                Text(date, style: .date)
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)
            }
            .padding(Spacing.xl)
        }
        .frame(width: cardSize.width, height: cardSize.height)
    }

}
