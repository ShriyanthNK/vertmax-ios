import Foundation
import SwiftData
import WidgetKit

/// Recomputes the widget's shared snapshot from the live SwiftData store and
/// nudges WidgetKit to redraw. Call this right after any mutation that could
/// change what the widget shows — a session completion, a saved measurement.
/// Lives in the main app target only: the widget extension never writes,
/// only reads via `WidgetSnapshotStore.load()`, so it doesn't need SwiftData
/// at all — see the curated source list in project.yml.
enum WidgetSnapshotRefresher {
    @MainActor
    static func refresh(context: ModelContext) {
        let measurements = (try? context.fetch(FetchDescriptor<JumpMeasurement>())) ?? []
        let completions = (try? context.fetch(FetchDescriptor<SessionCompletion>())) ?? []

        let best = measurements.max { $0.heightInches < $1.heightInches }
        let daysSinceLastMeasurement = best.map {
            Calendar.current.dateComponents([.day], from: $0.date, to: .now).day ?? 0
        }
        let streak = StreakCalculator.currentStreak(
            sessionDates: completions.map(\.completedAt),
            measurementDates: measurements.map(\.date)
        )

        WidgetSnapshotStore.save(VertmaxWidgetSnapshot(
            bestVertInches: best?.heightInches,
            bestVertDate: best?.date,
            currentStreak: streak,
            daysSinceLastMeasurement: daysSinceLastMeasurement
        ))
        WidgetCenter.shared.reloadAllTimelines()
    }
}
