import SwiftUI

/// Placeholder for the LLM-backed coach (PRD §5.4). Chat wiring, guardrails,
/// and context injection land in a later pass.
struct CoachView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ink.ignoresSafeArea()
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.textMuted)
                        .padding(Spacing.md)
                        .background(Circle().fill(Color.surface))

                    Text("COMING SOON")
                        .font(VertFont.eyebrow)
                        .foregroundStyle(.voltGreen)
                        .eyebrowTracking()
                        .padding(.top, Spacing.xs)

                    Text("Coach")
                        .font(VertFont.headline)
                        .foregroundStyle(.textPrimary)
                    Text("Your AI coach will answer training questions and explain your program here.")
                        .font(VertFont.caption)
                        .foregroundStyle(.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }
            }
            .navigationTitle("Coach")
            .profileToolbar()
        }
    }
}
