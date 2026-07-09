import Foundation

/// Small, App-Group-shared snapshot of what the widget needs to render.
/// The main app writes this on every mutation that could change it (a
/// session completion, a saved measurement); the widget extension only
/// ever reads it — it has no SwiftData access of its own, which keeps the
/// extension's process lightweight and avoids sharing the full model store
/// across processes.
struct VertmaxWidgetSnapshot: Codable {
    var bestVertInches: Double?
    var bestVertDate: Date?
    var currentStreak: Int
    var daysSinceLastMeasurement: Int?

    static let placeholder = VertmaxWidgetSnapshot(
        bestVertInches: 28.5,
        bestVertDate: .now,
        currentStreak: 4,
        daysSinceLastMeasurement: 2
    )
}

enum WidgetSnapshotStore {
    private static let suiteName = "group.com.vertmax.app"
    private static let key = "widgetSnapshot"

    static func save(_ snapshot: VertmaxWidgetSnapshot) {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    static func load() -> VertmaxWidgetSnapshot? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(VertmaxWidgetSnapshot.self, from: data)
    }
}
