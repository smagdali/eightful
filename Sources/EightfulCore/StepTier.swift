import Foundation

public enum StepTier: String, CaseIterable, Sendable {
    case red, orange, yellow, green

    public static func from(steps: Int) -> StepTier {
        switch steps {
        case ..<7_000: return .red
        case 7_000..<10_000: return .orange
        case 10_000..<12_500: return .yellow
        default: return .green
        }
    }

    /// Tier matching a Vitality point value (0/3/5/8). Used in week-view
    /// rows where the colour should reflect what was earned rather than
    /// how the user got there - a 5-pt workout on a 7k-step day reads as
    /// yellow (5 pts), not orange (steps tier alone).
    public static func from(points: Int) -> StepTier {
        switch points {
        case 8...: return .green
        case 5...: return .yellow
        case 3...: return .orange
        default:   return .red
        }
    }
}
