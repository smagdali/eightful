import Foundation

public enum NotificationAction: Equatable, Sendable {
    case suppress
    case nudge(NudgeZone)
    case report(DayState)
}

public enum NotificationDecision {
    /// Pure function: given today's state, the current time, settings, and the day's
    /// notification history, return what to do right now.
    public static func evaluate(
        state: DayState,
        now: Date,
        settings: AppSettings,
        history: NotificationHistory,
        calendar: Calendar = .current
    ) -> NotificationAction {
        guard settings.notificationsEnabled else { return .suppress }

        let nudgeStart = settings.nudgeStartTime.on(now, calendar: calendar)
        let reportStart = settings.reportTime.on(now, calendar: calendar)
        guard now >= nudgeStart else { return .suppress }

        // Report-time window (8pm by default): overrides suppression with a nudge
        // if the user is sitting in one of the three nudge zones.
        if now >= reportStart, !history.reportedToday {
            if let zone = state.nudgeZone {
                return .nudge(zone)
            }
            if state.isGreen {
                return .suppress
            }
            return .report(state)
        }

        // Pre-report window (>= nudgeStartTime and < reportStart): only fire nudges
        // for the step-threshold zones (not below12500 — that one is 8pm-only).
        if let zone = state.nudgeZone, zone != .below12500, !history.nudged(for: zone) {
            return .nudge(zone)
        }

        return .suppress
    }
}
