import SwiftUI
import WidgetKit
import EightfulCore

struct WatchRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var state: DayState?
    @State private var week: WeekReconciliation?
    @State private var phase: Phase = .loading
    @State private var lastUpdated: Date?
    @State private var refreshTask: Task<Void, Never>?
    private let settings = SettingsStore.shared

    enum Phase: Equatable { case loading, needsAuth, error(String), ready }

    var body: some View {
        VStack(spacing: 6) {
            switch phase {
            case .loading:
                ProgressView()
            case .needsAuth:
                VStack(spacing: 6) {
                    Text("Grant Health access")
                        .font(.headline).multilineTextAlignment(.center)
                    Text("Open the Eightful iPhone app and tap Grant Health, or approve the prompt here.")
                        .font(.caption2).multilineTextAlignment(.center).foregroundStyle(.secondary)
                    Button("Request again") { Task { await grantAndLoad() } }
                        .buttonStyle(.borderedProminent)
                }
            case .error(let msg):
                Text(msg).font(.caption2).foregroundStyle(.red).multilineTextAlignment(.center)
            case .ready:
                if let s = state {
                    Text(NumberFormatter.localizedString(from: NSNumber(value: s.steps), number: .decimal))
                        .font(.system(size: 58, weight: .heavy, design: .rounded))
                        .foregroundStyle(s.displayColor.color)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Text("\(s.points) pt\(s.points == 1 ? "" : "s")")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(s.displayColor.color.opacity(0.9))
                        if s.workoutGreen {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.green)
                        }
                    }
                    if let w = week {
                        WeekTable(week: w)
                            .padding(.top, 4)
                        Text("\(min(40, w.calculatedTotal)) / 40 this week")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(w.calculatedTotal >= 40 ? .green : .secondary)
                    }
                    if let updated = lastUpdated {
                        Text("Last updated: \(updated, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).second(.twoDigits))")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .accessibilityLabel("Last updated at \(updated.formatted(.dateTime.hour().minute().second()))")
                    }
                }
            }
        }
        .padding()
        .task { await grantAndLoad(); await loadWeek(); startAdaptiveRefresh() }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                // Tap-through from the complication: force-reload the
                // widget timeline so when the user flicks back to the
                // face it matches what they just saw in the app.
                Task { await refresh(forceWidgetReload: true); await loadWeek() }
                startAdaptiveRefresh()
            case .background, .inactive:
                stopAdaptiveRefresh()
                // One more nudge on exit so the freshest value is
                // queued before the user looks at the face again.
                WidgetCenter.shared.reloadAllTimelines()
            @unknown default: break
            }
        }
    }

    /// Re-poll on an adaptive interval: faster while stepping hard, slower while idle.
    /// Range: 60s (active) to 300s (idle). Activity of the user decides.
    private func startAdaptiveRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { @MainActor in
            var interval: TimeInterval = 30
            var lastSteps = state?.steps ?? 0
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                if Task.isCancelled { break }
                await refresh()
                let now = state?.steps ?? lastSteps
                let delta = now - lastSteps
                lastSteps = now
                if delta < 10 {
                    interval = min(300, interval * 2)
                } else if delta < 100 {
                    interval = 120
                } else {
                    interval = 60
                }
            }
        }
    }

    private func stopAdaptiveRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    private func refresh(forceWidgetReload: Bool = false) async {
        guard phase == .ready || phase == .loading else { return }
        if let s = try? await HealthKitReader.shared.currentDayState(settings: settings.settings) {
            let previous = state
            state = s
            lastUpdated = Date()
            phase = .ready
            LastStateCache.shared.save(s)
            // Update today's entry in the already-loaded week so the
            // week total reflects intraday changes without refetching
            // Mon-Sat from HealthKit.
            if let oldWeek = week {
                week = oldWeek.updating(today: s, calendar: .current)
            }
            let crossed = s.isMaterialChange(from: previous)
            let stale = WidgetReloadCoordinator.shared.shouldReloadOnIdle()
            if forceWidgetReload || crossed || stale {
                WidgetCenter.shared.reloadAllTimelines()
                WidgetReloadCoordinator.shared.markReloaded()
            }
        }
    }

    private func grantAndLoad() async {
        phase = .loading
        do {
            try await HealthKitReader.shared.requestAuthorization()
        } catch {
            phase = .needsAuth
            return
        }
        do {
            state = try await HealthKitReader.shared.currentDayState(settings: settings.settings)
            lastUpdated = Date()
            phase = .ready
            WidgetCenter.shared.reloadAllTimelines()
        } catch let err as NSError where err.domain == "com.apple.healthkit" && err.code == 5 {
            phase = .needsAuth
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    private func loadWeek() async {
        var cal = Calendar.current
        cal.firstWeekday = 2   // Monday
        let w = await HealthKitReader.shared.weekReconciliation(
            containing: Date(),
            settings: settings.settings,
            calendar: cal
        )
        await MainActor.run { self.week = w }
    }
}

/// Mon-Sun mini table showing the week's points per day.
/// Today's column highlighted with a dark pill.
/// Future days render as an em-dash.
private struct WeekTable: View {
    let week: WeekReconciliation
    private let letters = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(week.days.enumerated()), id: \.offset) { idx, entry in
                column(idx: idx, entry: entry)
            }
        }
    }

    @ViewBuilder
    private func column(idx: Int, entry: ReconciliationEntry) -> some View {
        let cal = Calendar.current
        let now = Date()
        let isToday = cal.isDate(entry.date, inSameDayAs: now)
        let isFuture = cal.startOfDay(for: entry.date) > cal.startOfDay(for: now)

        VStack(spacing: 2) {
            Text(letters[idx])
                .font(.system(size: 13, weight: isToday ? .bold : .medium, design: .rounded))
                .foregroundStyle(isToday ? .primary : Color(white: 0.5))
            if isFuture {
                Text("—")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(white: 0.4))
            } else {
                Text("\(entry.calculated.points)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(entry.calculated.effectiveTier.color)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? Color(white: 0.1) : .clear)
        )
    }
}

private extension WeekReconciliation {
    /// Returns a new WeekReconciliation with today's entry replaced by `newState`.
    /// Unchanged when today is outside this week (e.g. after midnight rollover before
    /// the next loadWeek call).
    func updating(today newState: DayState, calendar: Calendar) -> WeekReconciliation {
        let now = Date()
        guard let idx = days.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: now) })
        else { return self }
        var updated = days
        let existing = updated[idx]
        updated[idx] = ReconciliationEntry(date: existing.date, calculated: newState, reported: existing.reported)
        return WeekReconciliation(weekStart: weekStart, days: updated)
    }
}
