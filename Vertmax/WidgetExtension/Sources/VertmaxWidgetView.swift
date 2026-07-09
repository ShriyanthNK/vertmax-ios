import SwiftUI
import WidgetKit

struct VertmaxWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: VertEntry

    var body: some View {
        ZStack {
            switch family {
            case .systemMedium:
                mediumBody
            default:
                smallBody
            }
        }
        .containerBackground(for: .widget) { Color.ink }
    }

    private var heroNumberText: String {
        entry.snapshot.bestVertInches.map { String(format: "%.1f", $0) } ?? "––.–"
    }

    private var lastTestedText: String {
        guard let days = entry.snapshot.daysSinceLastMeasurement else { return "No tests yet" }
        return days == 0 ? "Tested today" : "\(days)d since last test"
    }

    private var smallBody: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text("BEST VERT")
                .font(VertFont.eyebrow)
                .foregroundStyle(.textMuted)
                .eyebrowTracking()

            Spacer(minLength: Spacing.xxs)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(heroNumberText)
                    .font(VertFont.numeric(30, weight: .semibold))
                    .foregroundStyle(.voltGreen)
                Text("in")
                    .font(VertFont.numeric(13, weight: .medium))
                    .foregroundStyle(.textMuted)
            }
            .minimumScaleFactor(0.7)
            .lineLimit(1)

            Spacer(minLength: Spacing.xxs)

            if entry.snapshot.currentStreak > 0 {
                streakBadge
            } else {
                Text(lastTestedText)
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
    }

    private var streakBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
                .font(.system(size: 11))
            Text("\(entry.snapshot.currentStreak) day streak")
                .font(VertFont.caption)
        }
        .foregroundStyle(.voltGreen)
    }

    private var mediumBody: some View {
        HStack(alignment: .center, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("BEST VERT")
                    .font(VertFont.eyebrow)
                    .foregroundStyle(.textMuted)
                    .eyebrowTracking()

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(heroNumberText)
                        .font(VertFont.numeric(34, weight: .semibold))
                        .foregroundStyle(.voltGreen)
                    Text("in")
                        .font(VertFont.numeric(14, weight: .medium))
                        .foregroundStyle(.textMuted)
                }
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: Spacing.xs) {
                if entry.snapshot.currentStreak > 0 {
                    streakBadge
                }
                Text(lastTestedText)
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)
            }
        }
        .padding(Spacing.md)
    }
}
