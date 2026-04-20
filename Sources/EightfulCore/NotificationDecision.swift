import Foundation

public enum NotificationAction: Equatable, Sendable {
    case suppress
    case nudge(NudgeZone)
    case report(DayState)
}

public enum NotificationDecision {
    /// Pure function: given today's state, the current time, settings, and the day's
    /// notification history, return what to do right now.
    ///
    /// One nudge per day at the user's chosen time:
    ///   - in a nudge zone (500 steps short of 7k/10k/12.5k): tell them how far to go
    ///   - already green (12,500+ or workout-earned): silence
    ///   - otherwise: report the day
    public static func evaluate(
        state: DayState,
        now: Date,
        settings: AppSettings,
        history: NotificationHistory,
        calendar: Calendar = .current
    ) -> NotificationAction {
        guard settings.notificationsEnabled else { return .suppress }
        guard now >= settings.nudgeTime.on(now, calendar: calendar) else { return .suppress }
        guard !history.reportedToday else { return .suppress }

        if let zone = state.nudgeZone { return .nudge(zone) }
        if state.isGreen { return .suppress }
        return .report(state)
    }
}
