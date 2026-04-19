import Foundation
import Combine
import EightfulCore

/// Persists user-entered "Vitality reported" points per calendar day.
/// Storage format: `[yyyy-MM-dd -> Int]` in UserDefaults.
public final class ReconciliationStore: ObservableObject {
    public static let shared = ReconciliationStore()

    private enum Key { static let reports = "eightful.reports.v1" }

    private let defaults: UserDefaults
    private let dateFormatter: DateFormatter

    @Published public private(set) var reports: [String: Int] = [:]

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.locale = Locale(identifier: "en_GB_POSIX")
        fmt.timeZone = TimeZone.current
        fmt.dateFormat = "yyyy-MM-dd"
        self.dateFormatter = fmt
        load()
    }

    private func load() {
        if let dict = defaults.dictionary(forKey: Key.reports) as? [String: Int] {
            reports = dict
        }
    }

    private func save() {
        defaults.set(reports, forKey: Key.reports)
    }

    public func key(for date: Date, calendar: Calendar = .current) -> String {
        dateFormatter.timeZone = calendar.timeZone
        return dateFormatter.string(from: calendar.startOfDay(for: date))
    }

    public func reported(for date: Date, calendar: Calendar = .current) -> Int? {
        reports[key(for: date, calendar: calendar)]
    }

    public func set(_ value: Int?, for date: Date, calendar: Calendar = .current) {
        let k = key(for: date, calendar: calendar)
        if let value {
            reports[k] = value
        } else {
            reports.removeValue(forKey: k)
        }
        save()
    }
}
