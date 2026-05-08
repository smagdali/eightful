import SwiftUI
import WidgetKit
import EightfulCore

struct HomeWidgetSmallView: View {
    let entry: StepsEntry

    var body: some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(for: .widget) { Color.clear }
        } else {
            content
        }
    }

    private var content: some View {
        let state = entry.state
        return VStack(spacing: 2) {
            Spacer(minLength: 0)

            Text(formatted(state.steps))
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(state.displayColor.color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text("\(state.points) pt\(state.points == 1 ? "" : "s")")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            Text("\(entry.weekPoints) this week")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Spacer(minLength: 0)

            Text(entry.date, format: .dateTime.hour().minute())
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private func formatted(_ n: Int) -> String {
    let fmt = NumberFormatter()
    fmt.numberStyle = .decimal
    return fmt.string(from: NSNumber(value: n)) ?? String(n)
}
