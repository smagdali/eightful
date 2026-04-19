import SwiftUI
import StepsToEightCore

struct ReconciliationView: View {
    @StateObject private var store = ReconciliationStore.shared
    @StateObject private var settingsStore = SettingsStore.shared
    @State private var weekOffset: Int = -1   // default: last week (lag-safe)
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
                    summarySection(week)
                    daysSection(week)
                    patternSection(week)
                } else if loading {
                    Section { ProgressView() }
                }
                helpSection
            }
            .navigationTitle("Compare with Vitality")
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
                    Text(weekOffset == 0 ? "this week (data may still be lagging)" :
                         weekOffset == -1 ? "last week (recommended)" :
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

    private func summarySection(_ week: WeekReconciliation) -> some View {
        Section("Week totals") {
            HStack {
                VStack(alignment: .leading) {
                    Text("Calculated")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("\(week.calculatedTotal) pt")
                        .font(.title3).bold()
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Reported (Vitality)")
                        .font(.caption).foregroundStyle(.secondary)
                    if let rt = week.reportedTotal {
                        Text("\(rt) pt")
                            .font(.title3).bold()
                            .foregroundStyle(rt == week.calculatedTotal ? .green : .orange)
                    } else {
                        Text("\(week.pendingCount) pending")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func daysSection(_ week: WeekReconciliation) -> some View {
        Section("Day by day") {
            ForEach(week.days, id: \.date) { entry in
                DayRow(entry: entry) { newVal in
                    store.set(newVal, for: entry.date)
                    Task { await load() }
                }
            }
        }
    }

    private func patternSection(_ week: WeekReconciliation) -> some View {
        Section("Pattern") {
            Text(week.pattern.humanReadable)
                .font(.callout)
        }
    }

    private var helpSection: some View {
        Section {
            Text("Open the Vitality Member app's Points Statement, then tap a day above to enter what Vitality shows. Use last week to avoid lag; a 2026-04-18 figure probably isn't final.")
                .font(.caption)
                .foregroundStyle(.secondary)
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
        let reports = store.reports
        let w = await HealthKitReader.shared.weekReconciliation(
            containing: currentWeekDate,
            settings: settingsStore.settings,
            reported: { date in
                let key = ReconciliationStore.shared.key(for: date, calendar: calendar)
                return reports[key]
            },
            calendar: calendar
        )
        await MainActor.run { self.week = w }
    }
}

private struct DayRow: View {
    let entry: ReconciliationEntry
    let onSet: (Int?) -> Void
    @State private var showEditor = false
    @State private var draft: String = ""

    var body: some View {
        Button { showEditor = true } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(dayLabel).font(.callout).bold()
                    Text("\(entry.calculated.steps) steps")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                statusPill
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showEditor) { editor }
    }

    private var dayLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE d MMM"
        return fmt.string(from: entry.date)
    }

    private var statusPill: some View {
        HStack(spacing: 10) {
            Text("\(entry.calculated.points) pt")
                .foregroundStyle(tierColor(entry.calculated.effectiveTier))
                .bold()
            Image(systemName: "arrow.left.arrow.right").font(.caption).foregroundStyle(.secondary)
            if let r = entry.reported {
                Text("\(r) pt")
                    .foregroundStyle(entry.status == .matched ? .green : .orange)
                    .bold()
            } else {
                Text("—")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var editor: some View {
        NavigationStack {
            Form {
                Section("Vitality says") {
                    TextField("points (0–8)", text: $draft)
                        .keyboardType(.numberPad)
                }
                Section {
                    Button("Pending (clear value)", role: .destructive) {
                        onSet(nil)
                        showEditor = false
                    }
                }
            }
            .navigationTitle(dayLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showEditor = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let v = Int(draft.trimmingCharacters(in: .whitespaces)), (0...8).contains(v) {
                            onSet(v)
                            showEditor = false
                        }
                    }
                }
            }
            .onAppear {
                if let r = entry.reported { draft = String(r) }
            }
        }
    }

    private func tierColor(_ tier: StepTier) -> Color { tier.color }
}
