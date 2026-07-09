import SwiftUI

/// Screen 6: mirrors back up to three of the user's own selected pain
/// points with Vertmax's specific answer to each — the "you told us your
/// problem, here's exactly how we fix it" bridge into the paid product.
struct OnboardingSolutionView: View {
    let sport: Sport
    let painPoints: Set<PainPoint>
    let onContinue: () -> Void

    private var rows: [(pain: String, solution: String, icon: String)] {
        let ordered: [PainPoint] = [.noPlan, .cantMeasure, .gotHurt, .genericPlans, .plateaued, .noTime, .noGym]
        let selected = ordered.filter { painPoints.contains($0) }
        let chosen = selected.isEmpty ? [.noPlan, .cantMeasure, .genericPlans] : Array(selected.prefix(3))
        return chosen.map(solution(for:))
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("Here's how Vertmax fixes that")
                .font(VertFont.screenTitle)
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, Spacing.lg)

            VStack(spacing: Spacing.sm) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: row.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(.voltGreen)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(row.pain)
                                .font(VertFont.caption)
                                .foregroundStyle(.textMuted)
                                .strikethrough()
                            Text(row.solution)
                                .font(VertFont.body(15, weight: .semibold))
                                .foregroundStyle(.textPrimary)
                        }
                        Spacer()
                    }
                    .padding(Spacing.md)
                    .cardStyle()
                }
            }

            Spacer(minLength: Spacing.md)

            Button("Continue", action: onContinue)
                .buttonStyle(VoltButtonStyle())
        }
    }

    private func solution(for point: PainPoint) -> (pain: String, solution: String, icon: String) {
        switch point {
        case .noPlan:
            return (point.label, "A program built from your sport and goal — every session mapped out", "list.bullet.clipboard")
        case .cantMeasure:
            return (point.label, "Frame-accurate camera measurement tracks every inch, every session", "camera.fill")
        case .gotHurt:
            return (point.label, "Injury-aware program routing keeps training safe", "checkmark.shield")
        case .genericPlans:
            return (point.label, "Sport-specific programming for \(sport.displayName)", "figure.run")
        case .noTime:
            return (point.label, "A clear week-by-week plan — no guesswork on what to do", "calendar")
        case .plateaued:
            return (point.label, "Progressive overload built into every week automatically", "arrow.up.forward")
        case .noGym:
            return (point.label, "Full programs built for bodyweight-only training too", "figure.core.training")
        }
    }
}
