import SwiftUI

/// Screen 7 (optional in the framework, included here for completeness):
/// makes the with/without contrast scannable in one glance. Rows compare
/// capabilities, not fabricated stats — there's no real usage data yet to
/// cite honestly.
struct OnboardingComparisonView: View {
    let onContinue: () -> Void

    private let rows: [(label: String, without: String, with: String)] = [
        ("Progress tracking", "Guessing", "Frame-accurate measurement"),
        ("Program", "Generic templates", "Built for your sport & goal"),
        ("Safety", "No injury routing", "Injury-aware programming"),
        ("Motivation", "No visible progress", "Streaks & PR history")
    ]

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("Training blind vs. training with Vertmax")
                .font(VertFont.screenTitle)
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, Spacing.lg)

            VStack(spacing: Spacing.md) {
                header
                ForEach(rows, id: \.label) { row in
                    comparisonRow(row)
                }
            }
            .padding(Spacing.md)
            .cardStyle()

            Spacer(minLength: Spacing.md)

            Button("Continue", action: onContinue)
                .buttonStyle(VoltButtonStyle())
        }
    }

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            Text("Without").font(VertFont.caption).foregroundStyle(.textMuted).frame(maxWidth: .infinity, alignment: .leading)
            Text("Vertmax").font(VertFont.caption).foregroundStyle(.voltGreen).frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func comparisonRow(_ row: (label: String, without: String, with: String)) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(row.label)
                .font(VertFont.body(13, weight: .semibold))
                .foregroundStyle(.textPrimary)
            HStack(alignment: .top, spacing: Spacing.sm) {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.stopRed)
                    Text(row.without).font(VertFont.caption).foregroundStyle(.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.voltGreen)
                    Text(row.with).font(VertFont.caption).foregroundStyle(.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}
