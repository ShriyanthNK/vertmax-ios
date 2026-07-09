import SwiftUI

/// Screen 1 of the framework: the hook. Shows the transformation outcome
/// before asking anything, so the questionnaire that follows feels like
/// it's in service of something the user already wants, not a cold form.
struct OnboardingWelcomeView: View {
    let onGetStarted: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer(minLength: Spacing.lg)

            VStack(spacing: Spacing.md) {
                VertmaxLogoMark()
                    .frame(width: 88, height: 88)
                    .reveal(appeared)
                VStack(spacing: Spacing.xs) {
                    Text("Add Inches To Your Vertical")
                        .font(VertFont.screenTitle)
                        .foregroundStyle(.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Measure it. Train for it. Prove it.")
                        .font(VertFont.bodyText)
                        .foregroundStyle(.textMuted)
                }
                .reveal(appeared, delay: 0.1)
            }

            previewCard
                .reveal(appeared, delay: 0.2)

            Spacer(minLength: Spacing.lg)

            Button("Get Started", action: onGetStarted)
                .buttonStyle(VoltButtonStyle())
                .reveal(appeared, delay: 0.3)
        }
        .padding(.horizontal, Spacing.lg)
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { appeared = true } }
    }

    /// Illustrative only, not live data — hints at the payoff (a tracked,
    /// rising number) the same way the widget mock does on the reveal screen.
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text("BEST VERT")
                .font(VertFont.eyebrow)
                .foregroundStyle(.textMuted)
                .eyebrowTracking()
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("31.2")
                    .font(VertFont.numeric(32, weight: .semibold))
                    .foregroundStyle(.voltGreen)
                Text("in")
                    .font(VertFont.numeric(14, weight: .medium))
                    .foregroundStyle(.textMuted)
            }
            HStack(spacing: 3) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10))
                Text("+4.8 in since Week 1")
                    .font(VertFont.caption)
            }
            .foregroundStyle(.voltGreen)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(accent: .voltGreen)
    }
}
