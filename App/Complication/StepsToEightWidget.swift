import WidgetKit
import SwiftUI
import StepsToEightCore

@main
struct StepsToEightWidgetBundle: WidgetBundle {
    var body: some Widget { StepsToEightWidget() }
}

struct StepsToEightWidget: Widget {
    let kind = "StepsToEightWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StepsProvider()) { entry in
            ComplicationView(entry: entry)
        }
        .configurationDisplayName("StepsToEight")
        .description("Today's steps, coloured by Vitality points target.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
            .accessoryInline,
        ])
    }
}
