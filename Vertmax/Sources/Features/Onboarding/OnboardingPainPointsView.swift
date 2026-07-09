import SwiftUI

/// Screen 3: multi-select pain points. Two jobs: (1) tells the user "this
/// app gets me" before the sell, and (2) feeds `OnboardingSolutionView`,
/// which mirrors back whichever of these the user actually picked.
struct OnboardingPainPointsView: View {
    @Binding var selected: Set<PainPoint>
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("What's holding back your vertical?")
                    .font(VertFont.screenTitle)
                    .foregroundStyle(.textPrimary)
                Text("Choose everything that's true for you.")
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)
            }
            .padding(.top, Spacing.lg)

            ScrollView {
                VStack(spacing: Spacing.sm) {
                    ForEach(PainPoint.allCases, id: \.self) { point in
                        OnboardingCheckRow(
                            title: point.label,
                            icon: point.icon,
                            isSelected: selected.contains(point)
                        ) {
                            if selected.contains(point) {
                                selected.remove(point)
                            } else {
                                selected.insert(point)
                            }
                        }
                    }
                }
                .padding(.bottom, Spacing.sm)
            }
            // Without this, the ScrollView sizes to its content instead of
            // the space actually available above the button, so with seven
            // rows the last couple render off the bottom of the screen
            // un-scrollable. This forces it to claim the remaining height.
            .frame(maxHeight: .infinity)

            Button("Continue", action: onContinue)
                .buttonStyle(VoltButtonStyle())
                .disabled(selected.isEmpty)
        }
    }
}

/// Checkbox-style row shared by any future multi-select onboarding screen.
private struct OnboardingCheckRow: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(.voltGreen)
                    .frame(width: 28)
                Text(title)
                    .font(VertFont.headline)
                    .foregroundStyle(.textPrimary)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .voltGreen : .textMuted)
            }
            .padding(Spacing.md)
            .cardStyle(accent: isSelected ? .voltGreen : nil)
        }
        .pressableRow()
    }
}
