import Foundation
import EightfulCore

/// Stashes the most recent successful `DayState` read in App-Group-backed
/// UserDefaults so the watch app and the widget extension (separate
/// processes) share a view of "what we last knew".
///
/// Used as a fallback when HealthKit / CoreMotion throw transiently -
/// better to show a slightly stale but realistic number than zero.
/// Entries older than the current calendar day are ignored on read;
/// we don't want yesterday's 14,000 to persist past midnight.
public final class LastStateCache {
    public static let shared = LastStateCache()

    private static let appGroup = "group.org.whitelabel.eightful"
    private static let key = "eightful.lastState.v1"
    private static let weekPointsKey = "eightful.lastWeekPoints.v1"
    private static let weekPointsTimestampKey = "eightful.lastWeekPoints.timestamp.v1"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults? = nil) {
        self.defaults = defaults ?? UserDefaults(suiteName: Self.appGroup) ?? .standard
    }

    public func save(_ state: DayState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: Self.key)
    }

    public func load(calendar: Calendar = .current, now: Date = Date()) -> DayState? {
        guard let data = defaults.data(forKey: Self.key),
              let state = try? JSONDecoder().decode(DayState.self, from: data),
              calendar.isDate(state.timestamp, inSameDayAs: now)
        else { return nil }
        return state
    }

    /// Cache the Mon-Sun running total alongside `DayState` so a cache-fallback
    /// render of the widget can still show "X this week" instead of zero.
    public func saveWeekPoints(_ points: Int, now: Date = Date()) {
        defaults.set(points, forKey: Self.weekPointsKey)
        defaults.set(now, forKey: Self.weekPointsTimestampKey)
    }

    /// Returns the cached week total only if it was written within the same
    /// Mon-Sun week as `now`. Crossing into a new week invalidates it.
    public func loadWeekPoints(calendar baseCalendar: Calendar = .current, now: Date = Date()) -> Int? {
        guard defaults.object(forKey: Self.weekPointsKey) != nil,
              let savedAt = defaults.object(forKey: Self.weekPointsTimestampKey) as? Date
        else { return nil }
        var cal = baseCalendar
        cal.firstWeekday = 2
        let savedWeek = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: savedAt)
        let nowWeek = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        guard savedWeek == nowWeek else { return nil }
        return defaults.integer(forKey: Self.weekPointsKey)
    }
}
