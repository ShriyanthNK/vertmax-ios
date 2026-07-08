import SwiftUI

/// Placeholder for the LLM-backed coach (PRD §5.4). Chat wiring, guardrails,
/// and context injection land in a later pass.
struct CoachView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ink.ignoresSafeArea()
                VStack(spacing: Spacing.xs) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.textMuted)
                    Text("Coach is coming soon")
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
