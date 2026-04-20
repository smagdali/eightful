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
    public var nudgeTime: TimeOfDay
    public var dobOverride: Date?

    public init(
        notificationsEnabled: Bool = true,
        nudgeTime: TimeOfDay = .eightPM,
        dobOverride: Date? = nil
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.nudgeTime = nudgeTime
        self.dobOverride = dobOverride
    }

    public static let `default` = AppSettings()

    private enum CodingKeys: String, CodingKey {
        case notificationsEnabled, nudgeTime, dobOverride
        case reportTime   // legacy field
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.notificationsEnabled = try c.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? true
        if let t = try c.decodeIfPresent(TimeOfDay.self, forKey: .nudgeTime) {
            self.nudgeTime = t
        } else if let legacy = try c.decodeIfPresent(TimeOfDay.self, forKey: .reportTime) {
            self.nudgeTime = legacy
        } else {
            self.nudgeTime = .eightPM
        }
        self.dobOverride = try c.decodeIfPresent(Date.self, forKey: .dobOverride)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(notificationsEnabled, forKey: .notificationsEnabled)
        try c.encode(nudgeTime, forKey: .nudgeTime)
        try c.encodeIfPresent(dobOverride, forKey: .dobOverride)
    }
}
