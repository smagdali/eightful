import WidgetKit
import SwiftUI
import EightfulCore

@main
struct EightfulWidgetBundle: WidgetBundle {
    var body: some Widget { EightfulWidget() }
}

struct EightfulWidget: Widget {
    let kind = "EightfulWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StepsProvider()) { entry in
            HomeWidgetSmallView(entry: entry)
        }
        .configurationDisplayName("Eightful")
        .description("Today's steps, points, and last update.")
        .supportedFamilies([.systemSmall])
    }
}
