import SwiftUI

/// Compact exercise line for "up next" style cards: name in body copy,
/// set×rep in the mono data face — the same "measured value" language as
/// the hero number, just quieter. Shared by Home and the Program tab so
/// their "up next" cards read as the same component, not two similar ones.
struct ExerciseSummaryRow: View {
    let name: String
    let sets: Int
    let reps: String

    var body: some View {
        (
            Text("\(name)  ")
                .font(VertFont.caption)
                .foregroundStyle(.textMuted)
            + Text("\(sets)×\(reps)")
                .font(VertFont.dataCaption)
                .foregroundStyle(.textMuted)
        )
    }
}
