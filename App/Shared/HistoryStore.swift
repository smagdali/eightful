import Foundation
import StepsToEightCore

/// Persists NotificationHistory across launches. Auto-resets on a new local calendar day.
public final class HistoryStore {
    public static let shared = HistoryStore()

    private enum Key { static let history = "stepstoeight.history.v1" }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load(now: Date = Date(), calendar: Calendar = .current) -> NotificationHistory {
        let fresh = NotificationHistory.empty(for: now, calendar: calendar)
        guard let data = defaults.data(forKey: Key.history),
              let decoded = try? JSONDecoder().decode(NotificationHistory.self, from: data) else {
            save(fresh)
            return fresh
        }
        return decoded.rolledOver(to: now, calendar: calendar)
    }

    public func save(_ history: NotificationHistory) {
        guard let data = try? JSONEncoder().encode(history) else { return }
        defaults.set(data, forKey: Key.history)
    }
}
