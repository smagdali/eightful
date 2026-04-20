import SwiftUI
import EightfulCore

struct ReconciliationView: View {
    @StateObject private var settingsStore = SettingsStore.shared
    @State private var weekOffset: Int = -1   // default: last week
    @State private var week: WeekReconciliation?
    @State private var loading: Bool = false

    private var calendar: Calendar {
        var c = Calendar.current
        c.firstWeekday = 2
        return c
    }

    private var currentWeekDate: Date {
        let today = Date()
        return calendar.date(byAdding: .day, value: weekOffset * 7, to: today) ?? today
    }

    var body: some View {
        NavigationStack {
            List {
                weekPickerSection
                if let week {
                    totalSection(week)
                    daysSection(week)
                } else if loading {
                    Section { ProgressView() }
                }
            }
            .navigationTitle("Week")
            .task(id: weekOffset) { await load() }
        }
    }

    private var weekPickerSection: some View {
        Section {
            HStack {
                Button { weekOffset -= 1 } label: { Image(systemName: "chevron.left") }
                Spacer()
                VStack {
                    Text(weekLabel).font(.headline)
                    Text(weekOffset == 0 ? "this week" :
                         weekOffset == -1 ? "last week" :
                         "\(abs(weekOffset)) weeks ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Button { if weekOffset < 0 { weekOffset += 1 } } label: { Image(systemName: "chevron.right") }
                    .disabled(weekOffset >= 0)
            }
        }
    }

    private func totalSection(_ week: WeekReconciliation) -> some View {
        Section("Week total") {
            HStack(alignment: .firstTextBaseline) {
                Text("\(week.calculatedTotal)")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                Text("points")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("of 40 weekly cap")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private func daysSection(_ week: WeekReconciliation) -> some View {
        Section("Day by day") {
            ForEach(week.days, id: \.date) { entry in
                DayRow(entry: entry)
            }
        }
    }

    private var weekLabel: String {
        guard let week else { return " " }
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        let start = week.weekStart
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        return "\(fmt.string(from: start)) — \(fmt.string(from: end))"
    }

    private func load() async {
        loading = true
        defer { loading = false }
        let w = await HealthKitReader.shared.weekReconciliation(
            containing: currentWeekDate,
            settings: settingsStore.settings,
            calendar: calendar
        )
        await MainActor.run { self.week = w }
    }
}

private struct DayRow: View {
    let entry: ReconciliationEntry

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dayLabel).font(.callout).bold()
                Text("\(formatted(entry.calculated.steps)) steps")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(entry.calculated.points) pt")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(entry.calculated.effectiveTier.color)
        }
        .padding(.vertical, 2)
    }

    private var dayLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE d MMM"
        return fmt.string(from: entry.date)
    }

    private func formatted(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? String(n)
    }
}
