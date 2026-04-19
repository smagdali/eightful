import Foundation

/// Time-of-day value (hours + minutes only), independent of calendar day.
public struct TimeOfDay: Equatable, Sendable, Codable {
    public let hour: Int
    public let minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    public static let sevenPM = TimeOfDay(hour: 19, minute: 0)
    public static let eightPM = TimeOfDay(hour: 20, minute: 0)

    /// Resolve this time-of-day against a given date's calendar day.
    public func on(_ date: Date, calendar: Calendar = .current) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: DateComponents(hour: hour, minute: minute), to: startOfDay) ?? startOfDay
    }
}

public struct AppSettings: Equatable, Sendable, Codable {
    public var notificationsEnabled: Bool
    public var nudgeStartTime: TimeOfDay
    public var reportTime: TimeOfDay
    public var dobOverride: Date?

    public init(
        notificationsEnabled: Bool = true,
        nudgeStartTime: TimeOfDay = .sevenPM,
        reportTime: TimeOfDay = .eightPM,
        dobOverride: Date? = nil
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.nudgeStartTime = nudgeStartTime
        self.reportTime = reportTime
        self.dobOverride = dobOverride
    }

    public static let `default` = AppSettings()
}
