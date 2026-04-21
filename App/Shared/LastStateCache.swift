import Foundation
import EightfulCore

/// Stashes the most recent successful `DayState` read in App-Group-backed
/// UserDefaults so the watch app and the widget extension (separate
/// processes) share a view of "what we last knew".
///
/// Used as a fallback when HealthKit / CoreMotion throw transiently —
/// better to show a slightly stale but realistic number than zero.
/// Entries older than the current calendar day are ignored on read;
/// we don't want yesterday's 14,000 to persist past midnight.
public final class LastStateCache {
    public static let shared = LastStateCache()

    private static let appGroup = "group.org.whitelabel.eightful"
    private static let key = "eightful.lastState.v1"

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
}
