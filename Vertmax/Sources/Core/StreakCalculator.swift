import Foundation

/// Consistency streak: consecutive calendar days, up to today, with at least
/// one logged activity (a completed session or a jump measurement — either
/// counts, since both represent showing up). Mirrors the Duolingo-style
/// convention: the streak stays "alive" through today even if today has no
/// activity yet, but breaks once a full day is skipped.
enum StreakCalculator {
    static func currentStreak(sessionDates: [Date], measurementDates: [Date], calendar: Calendar = .current, today: Date = .now) -> Int {
        let activityDays = Set(
            (sessionDates + measurementDates).map { calendar.startOfDay(for: $0) }
        )
        guard !activityDays.isEmpty else { return 0 }

        let todayStart = calendar.startOfDay(for: today)
        var cursor = todayStart
        if !activityDays.contains(cursor) {
            // No activity yet today — look back starting from yesterday
            // instead, so the streak doesn't zero out before the day ends.
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
            guard activityDays.contains(cursor) else { return 0 }
        }

        var streak = 0
        while activityDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    /// Whole calendar days between `date` and now — the shared definition of
    /// "days since" used for both the in-app retest banner (HomeView) and
    /// the widget's "Xd since last test" line, so the two can't disagree
    /// about what "3 days ago" means.
    static func daysSince(_ date: Date?, calendar: Calendar = .current, today: Date = .now) -> Int? {
        guard let date else { return nil }
        return calendar.dateComponents([.day], from: date, to: today).day
    }
}
