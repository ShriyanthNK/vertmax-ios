import SwiftUI

/// PLACEHOLDER testimonials — replace with real user quotes or App Store
/// reviews before shipping. First-name-only plus a persona tag, no
/// fabricated surnames or photos, so nothing here could pass as a verified
/// review if this ships before real ones are collected.
private struct Testimonial: Identifiable {
    let id = UUID()
    let name: String
    let persona: String
    let quote: String
}

private let testimonials = [
    Testimonial(name: "Jordan", persona: "Basketball, Junior Year", quote: "I finally have a real plan instead of guessing at YouTube workouts."),
    Testimonial(name: "Maya", persona: "Volleyball, Club Player", quote: "Seeing the actual number every week is what keeps me consistent."),
    Testimonial(name: "Chris", persona: "Training for the Combine", quote: "Structured weeks, no more wondering if today's workout even matters.")
]

/// Screen 4: social proof. Reduces "will this actually work for someone
/// like me" risk before the sell in `OnboardingSolutionView`.
struct OnboardingSocialProofView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.xxs) {
                Text("You're not training alone")
                    .font(VertFont.screenTitle)
                    .foregroundStyle(.textPrimary)
                Text("Athletes across every sport train with Vertmax.")
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)
            }
            .padding(.top, Spacing.lg)

            VStack(spacing: Spacing.sm) {
                ForEach(testimonials) { t in
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("\u{201C}\(t.quote)\u{201D}")
                            .font(VertFont.body(15))
                            .foregroundStyle(.textPrimary)
                        Text("\(t.name) — \(t.persona)")
                            .font(VertFont.caption)
                            .foregroundStyle(.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                    .cardStyle()
                }
            }

            Spacer(minLength: Spacing.md)

            Button("Continue", action: onContinue)
                .buttonStyle(VoltButtonStyle())
        }
    }
}
