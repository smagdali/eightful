import Foundation

/// User-facing notification strings. Kept separate from the decision logic so tests
/// can assert decisions without locking copy, and so localization can plug in here.
public enum NotificationCopy {
    public struct Message: Equatable, Sendable {
        public let title: String
        public let body: String
    }

    public static func message(for action: NotificationAction) -> Message? {
        switch action {
        case .suppress:
            return nil

        case .nudge(let zone):
            return nudge(zone: zone, steps: nil)

        case .report(let state):
            let points = VitalityPoints.fromSteps(state.steps)
            let pointsText = "\(points) point\(points == 1 ? "" : "s")"
            if let next = nextTierGap(steps: state.steps) {
                return Message(
                    title: "\(formatSteps(state.steps)) steps - \(pointsText) - \(formatSteps(next.gap)) more to \(next.points) points",
                    body: ""
                )
            }
            return Message(
                title: "\(formatSteps(state.steps)) steps - \(pointsText)",
                body: ""
            )
        }
    }

    /// Steps remaining to the next points tier, and the points value at that
    /// threshold. Returns nil when the user is already at the top tier (8 pts).
    static func nextTierGap(steps: Int) -> (gap: Int, points: Int)? {
        if steps < 7_000  { return (7_000 - steps,  3) }
        if steps < 10_000 { return (10_000 - steps, 5) }
        if steps < 12_500 { return (12_500 - steps, 8) }
        return nil
    }

    public static func nudge(zone: NudgeZone, steps: Int?) -> Message {
        let gap = steps.map { max(0, zone.threshold - $0) }
        let gapText = gap.map { " (\($0) to go)" } ?? ""
        switch zone {
        case .below7k:
            return Message(
                title: "Almost at 7,000\(gapText)",
                body: "Hit 7,000 today to earn 3 Vitality points."
            )
        case .below10k:
            return Message(
                title: "Almost at 10,000\(gapText)",
                body: "Just a little more for 5 Vitality points."
            )
        case .below12500:
            return Message(
                title: "Nearly there\(gapText)",
                body: "Reach 12,500 for the full 8 points today."
            )
        }
    }

    private static func formatSteps(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? String(n)
    }
}
