import SwiftUI
import WidgetKit

struct VertmaxWidget: Widget {
    let kind = "VertmaxWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VertmaxWidgetProvider()) { entry in
            VertmaxWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Your Vert")
        .description("Best vert, streak, and days since your last test.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct VertmaxWidgetBundle: WidgetBundle {
    var body: some Widget {
        VertmaxWidget()
    }
}
