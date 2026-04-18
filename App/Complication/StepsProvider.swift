import WidgetKit
import StepsToEightCore

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
            let state = (try? await HealthKitReader.shared.currentDayState(settings: SettingsStore.shared.settings))
                ?? DayState(steps: 0, workoutGreen: false)
            completion(StepsEntry(date: Date(), state: state))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StepsEntry>) -> Void) {
        Task {
            let now = Date()
            let state = (try? await HealthKitReader.shared.currentDayState(settings: SettingsStore.shared.settings))
                ?? DayState(steps: 0, workoutGreen: false, timestamp: now)

            let calendar = Calendar.current
            let startOfTomorrow = calendar.startOfDay(for: now.addingTimeInterval(24 * 60 * 60))

            // A single entry now, re-evaluated at local midnight. HealthKit observer in the
            // watch app will kick WidgetCenter.reloadAllTimelines() whenever steps change,
            // so we don't need dense timeline entries.
            let entry = StepsEntry(date: now, state: state)
            let midnightEntry = StepsEntry(date: startOfTomorrow, state: DayState(steps: 0, workoutGreen: false, timestamp: startOfTomorrow))
            let timeline = Timeline(entries: [entry, midnightEntry], policy: .after(startOfTomorrow))
            completion(timeline)
        }
    }
}
