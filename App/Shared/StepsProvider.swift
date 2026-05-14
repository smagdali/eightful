import WidgetKit
import EightfulCore
import Foundation

struct StepsEntry: TimelineEntry {
    let date: Date
    let state: DayState
    /// Sum of `points` across the current Mon-Sun week (including today).
    /// Capped by Vitality at 40/week, but we don't clamp here - leave that
    /// to the view layer if it ever wants to display "of 40".
    let weekPoints: Int
}

struct StepsProvider: TimelineProvider {
    func placeholder(in context: Context) -> StepsEntry {
        StepsEntry(date: Date(), state: DayState(steps: 8_432, workoutGreen: false), weekPoints: 23)
    }

    func getSnapshot(in context: Context, completion: @escaping (StepsEntry) -> Void) {
        if ScreenshotMode.isActive {
            completion(StepsEntry(
                date: Date(),
                state: ScreenshotMode.sampleDayState,
                weekPoints: ScreenshotMode.sampleWeek().calculatedTotal
            ))
            return
        }
        Task {
            let freshState = await readState()
            let state = freshState ?? DayState(steps: 0, workoutGreen: false)
            let week: Int
            if freshState != nil {
                week = await readWeekPoints() ?? LastStateCache.shared.loadWeekPoints() ?? 0
            } else {
                week = LastStateCache.shared.loadWeekPoints() ?? 0
            }
            completion(StepsEntry(date: Date(), state: state, weekPoints: week))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StepsEntry>) -> Void) {
        if ScreenshotMode.isActive {
            // Static photogenic entry; refresh hourly. No HealthKit, no cache writes.
            let now = Date()
            let entry = StepsEntry(
                date: now,
                state: ScreenshotMode.sampleDayState,
                weekPoints: ScreenshotMode.sampleWeek().calculatedTotal
            )
            completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(3600))))
            return
        }
        Task {
            let now = Date()
            let calendar = Calendar.current
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(24 * 60 * 60)
            let startOfTomorrow = calendar.startOfDay(for: tomorrow)

            let fresh = await readState()
            let state: DayState
            let policy: TimelineReloadPolicy

            if let fresh {
                // Good read - persist and coast until the next material change
                // or ~30 min, whichever comes first. Avoids the "stale 0 sticks
                // on the face until midnight" failure mode if the next refresh
                // doesn't happen via observer.
                LastStateCache.shared.save(fresh)
                state = fresh
                let nextCheck = now.addingTimeInterval(30 * 60)
                policy = .after(min(nextCheck, startOfTomorrow))
            } else if let cached = LastStateCache.shared.load(calendar: calendar, now: now) {
                // HealthKit / CoreMotion failed. Prefer today's last good value
                // over a spurious 0 on the face. Retry soon.
                state = cached
                policy = .after(now.addingTimeInterval(5 * 60))
            } else {
                // First-ever render, or cache from another day. Fall back to 0
                // but ask for a quick retry.
                state = DayState(steps: 0, workoutGreen: false, timestamp: now)
                policy = .after(now.addingTimeInterval(5 * 60))
            }

            // Week total: try fresh, fall back to cached, then to 0. Persist
            // freshly-computed values so cache-fallback renders aren't blank.
            let freshWeek: Int?
            if fresh == nil {
                freshWeek = nil
            } else {
                freshWeek = await readWeekPoints()
            }
            if let freshWeek { LastStateCache.shared.saveWeekPoints(freshWeek) }
            let weekPoints = freshWeek ?? LastStateCache.shared.loadWeekPoints() ?? 0
            let midnightWeekPoints = isSameMondayWeek(now, startOfTomorrow, calendar: calendar) ? weekPoints : 0

            let entry = StepsEntry(date: now, state: state, weekPoints: weekPoints)
            let midnightEntry = StepsEntry(
                date: startOfTomorrow,
                state: DayState(steps: 0, workoutGreen: false, timestamp: startOfTomorrow),
                weekPoints: midnightWeekPoints
            )
            completion(Timeline(entries: [entry, midnightEntry], policy: policy))
        }
    }

    /// Single attempt to read the current day state. Errors are logged-and-nil
    /// so the caller can decide between "use cache" and "show zero".
    private func readState() async -> DayState? {
        do {
            return try await HealthKitReader.shared.currentDayState(settings: SettingsStore.shared.settings)
        } catch {
            return nil
        }
    }

    /// Sum of points across this Mon-Sun week. Nil on HK failure.
    private func readWeekPoints() async -> Int? {
        let week = await HealthKitReader.shared.weekReconciliation(
            containing: Date(),
            settings: SettingsStore.shared.settings
        )
        // weekReconciliation never throws - it swallows per-day errors and
        // substitutes zero. So a literal 0 here might mean "all days failed".
        // We accept that: treat 0 as a legitimate (if depressing) week total.
        return week.calculatedTotal
    }

    private func isSameMondayWeek(_ lhs: Date, _ rhs: Date, calendar baseCalendar: Calendar = .current) -> Bool {
        var cal = baseCalendar
        cal.firstWeekday = 2
        return cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lhs) ==
            cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: rhs)
    }
}
