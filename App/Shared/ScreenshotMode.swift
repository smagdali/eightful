import Foundation
import EightfulCore

/// Activated by passing `--screenshots` as a launch argument (Xcode scheme ->
/// Run -> Arguments). When active, the views skip HealthKit and render a
/// fixed, photogenic state so we can capture App Store screenshots in the
/// simulator without injecting test data into HealthKit.
///
/// The flag is mirrored into App-Group UserDefaults on host-app launch so
/// the widget extension (a separate process that doesn't see the host's
/// launch arguments) renders the same canned state.
enum ScreenshotMode {
    private static let appGroup = "group.org.whitelabel.eightful"
    private static let key = "eightful.screenshotMode.v1"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }

    static var isActive: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--screenshots") { return true }
        return defaults?.bool(forKey: key) ?? false
        #else
        return false
        #endif
    }

    /// Call from the host app at launch so the widget extension picks up
    /// the same flag. Returns true if the flag's value actually changed
    /// (so the caller can decide whether a widget reload is warranted).
    /// Idempotent and cheap.
    @discardableResult
    static func syncFromLaunchArguments() -> Bool {
        #if DEBUG
        let active = ProcessInfo.processInfo.arguments.contains("--screenshots")
        let previous = defaults?.bool(forKey: key) ?? false
        defaults?.set(active, forKey: key)
        return active != previous
        #else
        return false
        #endif
    }

    /// Today: 8,347 steps, 3 pts (orange tier - sweet spot to show the colour
    /// system without cluttering with a workout banner).
    static var sampleDayState: DayState {
        DayState(steps: 8_347, workoutGreen: false)
    }

    /// Last week: a mix of green / yellow / orange days totalling 36 pts (just
    /// short of the 40 cap, so the "of 40 weekly cap" framing makes sense).
    /// Always returns Mon-Sun ending on the user's last completed week.
    static func sampleWeek(now: Date = Date(), calendar baseCalendar: Calendar = .current) -> WeekReconciliation {
        var cal = baseCalendar
        cal.firstWeekday = 2 // Monday

        // Walk back to last week's Monday.
        let startOfThisWeek = cal.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let lastMonday = cal.date(byAdding: .day, value: -7, to: startOfThisWeek) ?? now

        // Steps tuned to land on the matching point tier.
        let stepsByDay = [7_366, 12_557, 14_474, 10_112, 8_805, 13_201, 9_800]
        let days: [ReconciliationEntry] = stepsByDay.enumerated().map { offset, steps in
            let date = cal.date(byAdding: .day, value: offset, to: lastMonday) ?? lastMonday
            return ReconciliationEntry(
                date: date,
                calculated: DayState(steps: steps, workoutGreen: false, timestamp: date)
            )
        }
        return WeekReconciliation(weekStart: lastMonday, days: days)
    }
}
