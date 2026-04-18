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
}
