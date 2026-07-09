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

                credibilityBadge

                if takeoffImage != nil || landingImage != nil {
                    HStack(spacing: Spacing.md) {
                        frameThumb(takeoffImage)
                        frameThumb(landingImage)
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
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
        .clipShape(Capsule())
    }

    private func frameThumb(_ image: CGImage?) -> some View {
        Group {
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.surface
            }
        }
        .frame(width: 100, height: 130)
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.sm)
                .strokeBorder(Color.voltGreen.opacity(0.5), lineWidth: 1.5)
        )
    }
}
