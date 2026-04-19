import Foundation

/// Tracks which notifications have already fired for a given calendar day.
/// Intended to be persisted and re-hydrated per-day. Midnight rollover discards yesterday.
public struct NotificationHistory: Equatable, Sendable, Codable {
    public var day: Date           // startOfDay in local calendar
    public var reportedToday: Bool
    public var nudgedZones: Set<NudgeZone.RawValue>

    public init(day: Date, reportedToday: Bool = false, nudgedZones: Set<NudgeZone.RawValue> = []) {
        self.day = day
        self.reportedToday = reportedToday
        self.nudgedZones = nudgedZones
    }

    public static func empty(for date: Date, calendar: Calendar = .current) -> NotificationHistory {
        NotificationHistory(day: calendar.startOfDay(for: date))
    }

    public func nudged(for zone: NudgeZone) -> Bool {
        nudgedZones.contains(zone.rawValue)
    }

    public func markingNudged(_ zone: NudgeZone) -> NotificationHistory {
        var copy = self
        copy.nudgedZones.insert(zone.rawValue)
        return copy
    }

    public func markingReported() -> NotificationHistory {
        var copy = self
        copy.reportedToday = true
        return copy
    }

    /// Returns a fresh history if the stored day does not match `date`'s local day.
    public func rolledOver(to date: Date, calendar: Calendar = .current) -> NotificationHistory {
        let today = calendar.startOfDay(for: date)
        if today == day { return self }
        return NotificationHistory(day: today)
    }
}
