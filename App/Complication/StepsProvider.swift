import WidgetKit
import EightfulCore

struct StepsEntry: TimelineEntry {
    let date: Date
    let state: DayState
}

struct StepsProvider: TimelineProvider {
    func placeholder(in context: Context) -> StepsEntry {
        StepsEntry(date: Date(), state: DayState(steps: 8_432, workoutGreen: false))
    }

    func getSnapshot(in context: Context, completion: @escaping (StepsEntry) -> Void) {
        Task {
            let state = await readState() ?? DayState(steps: 0, workoutGreen: false)
            completion(StepsEntry(date: Date(), state: state))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StepsEntry>) -> Void) {
        Task {
            let now = Date()
            let calendar = Calendar.current
            let startOfTomorrow = calendar.startOfDay(for: now.addingTimeInterval(24 * 60 * 60))

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

            let entry = StepsEntry(date: now, state: state)
            let midnightEntry = StepsEntry(
                date: startOfTomorrow,
                state: DayState(steps: 0, workoutGreen: false, timestamp: startOfTomorrow)
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
}
