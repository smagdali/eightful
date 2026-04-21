import SwiftUI
import WidgetKit
import EightfulCore

struct ComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StepsEntry

    var body: some View {
        if #available(watchOS 10.0, *) {
            content.containerBackground(for: .widget) { Color.clear }
        } else {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryCircular:    CircularView(state: entry.state)
        case .accessoryRectangular: RectangularView(state: entry.state)
        case .accessoryCorner:      CornerView(state: entry.state)
        case .accessoryInline:      InlineView(state: entry.state)
        default:                    CircularView(state: entry.state)
        }
    }
}

private struct CircularView: View {
    let state: DayState
    var body: some View {
        ZStack {
            if state.workoutGreen {
                Circle()
                    .stroke(state.displayColor.color, lineWidth: 2.5)
                    .padding(1)
            }
            VStack(spacing: -2) {
                Text(shortened(state.steps))
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(state.displayColor.color)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("\(state.points)pt")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(state.displayColor.color.opacity(0.85))
            }
        }
    }
}

private struct RectangularView: View {
    let state: DayState
    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle().fill(state.displayColor.color.opacity(0.2))
                if state.workoutGreen {
                    Circle().stroke(state.displayColor.color, lineWidth: 1.5)
                }
                Image(systemName: "figure.walk")
                    .foregroundStyle(state.displayColor.color)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 0) {
                Text("\(formatted(state.steps)) steps")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(state.displayColor.color)
                Text("\(state.points) pt\(state.points == 1 ? "" : "s") today")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .widgetAccentable(true)
    }
}

private struct CornerView: View {
    let state: DayState
    var body: some View {
        Text("\(state.points)pt")
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(state.displayColor.color)
            .widgetLabel(state.workoutGreen
                         ? "\(formatted(state.steps)) steps (workout)"
                         : "\(formatted(state.steps)) steps")
    }
}

private struct InlineView: View {
    let state: DayState
    var body: some View {
        let label = state.workoutGreen
            ? "\(formatted(state.steps)) steps - 8 pts (workout)"
            : "\(formatted(state.steps)) steps - \(state.points) pts"
        Text(label)
    }
}

private func formatted(_ n: Int) -> String {
    let fmt = NumberFormatter()
    fmt.numberStyle = .decimal
    return fmt.string(from: NSNumber(value: n)) ?? String(n)
}

/// Compact form for small views: 8.4k instead of 8,432.
private func shortened(_ n: Int) -> String {
    if n < 1_000 { return String(n) }
    let thousands = Double(n) / 1_000.0
    if thousands >= 10 {
        return String(Int(thousands.rounded())) + "k"
    }
    return String(format: "%.1fk", thousands)
}
