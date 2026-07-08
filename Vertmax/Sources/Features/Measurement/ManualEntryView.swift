import SwiftUI

/// Wall-touch fallback (PRD §5.2) for users who can't film: standing reach
/// and jump touch height, both marked at a wall, entered manually.
struct ManualEntryView: View {
    let onSaved: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var standingReach: String = ""
    @State private var jumpTouch: String = ""

    private var computedHeight: Double? {
        guard let reach = Double(standingReach), let touch = Double(jumpTouch), touch > reach else { return nil }
        return touch - reach
    }

    var body: some View {
        ZStack {
            Color.ink.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                VStack(spacing: Spacing.xxs) {
                    Text("Wall-Touch Method")
                        .font(VertFont.title)
                        .foregroundStyle(.textPrimary)
                    Text("Mark your standing reach, then your highest jump touch, both against a wall.")
                        .font(VertFont.caption)
                        .foregroundStyle(.textMuted)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: Spacing.sm) {
                    field(label: "Standing reach (in)", text: $standingReach)
                    field(label: "Jump touch (in)", text: $jumpTouch)
                }

                if let computedHeight {
                    Text(String(format: "%.1f in", computedHeight))
                        .font(VertFont.heroNumber)
                        .foregroundStyle(.voltGreen)
                }

                Spacer()

                Button("Save Measurement") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .tint(.voltGreen)
                .foregroundStyle(.ink)
                .disabled(computedHeight == nil)
            }
            .padding(Spacing.lg)
        }
    }

    private func field(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(label)
                .font(VertFont.caption)
                .foregroundStyle(.textMuted)
            TextField("0.0", text: text)
                .keyboardType(.decimalPad)
                .font(VertFont.body(20, weight: .semibold))
                .foregroundStyle(.textPrimary)
                .padding(Spacing.sm)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
        }
    }

    private func save() {
        guard let computedHeight else { return }
        let measurement = JumpMeasurement(
            jumpType: .standing,
            heightInches: computedHeight,
            source: .manualEntry
        )
        modelContext.insert(measurement)
        try? modelContext.save()
        onSaved()
    }
}
