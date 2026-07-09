import WidgetKit

struct VertEntry: TimelineEntry {
    let date: Date
    let snapshot: VertmaxWidgetSnapshot
}

/// Widgets don't have SwiftData access — this only ever reads the snapshot
/// the main app wrote to the shared App Group. No async data fetch needed,
/// so the timeline is a single entry refreshed hourly as a floor, plus
/// on-demand reloads the app triggers via `WidgetCenter.reloadAllTimelines()`
/// right after it writes a new snapshot.
///
/// `.placeholder`'s fabricated numbers are only ever shown for the redacted
/// loading skeleton (`placeholder(in:)`) and the widget gallery preview
/// (`getSnapshot` when `context.isPreview`) — a real user's actual home
/// screen (`getTimeline`, and `getSnapshot` outside preview) falls back to
/// `.empty` instead, so someone who's never measured a jump sees an honest
/// "not measured yet" widget rather than someone else's fake 28.5".
struct VertmaxWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> VertEntry {
        VertEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (VertEntry) -> Void) {
        let snapshot = context.isPreview ? .placeholder : (WidgetSnapshotStore.load() ?? .empty)
        completion(VertEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VertEntry>) -> Void) {
        let entry = VertEntry(date: .now, snapshot: WidgetSnapshotStore.load() ?? .empty)
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}
