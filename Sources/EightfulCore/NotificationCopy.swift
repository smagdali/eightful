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
            if state.workoutGreen {
                return Message(
                    title: "Green via workout",
                    body: "Full 8 points already locked in. \(formatSteps(state.steps)) steps so far today."
                )
            }
            let points = VitalityPoints.fromSteps(state.steps)
            return Message(
                title: "\(formatSteps(state.steps)) steps today",
                body: "\(state.tier.rawValue.capitalized) tier, \(points) point\(points == 1 ? "" : "s")."
            )
        }
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
