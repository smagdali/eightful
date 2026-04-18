import Foundation

public enum NudgeZone: String, CaseIterable, Sendable {
    case below7k, below10k, below12500

    public var threshold: Int {
        switch self {
        case .below7k: return 7_000
        case .below10k: return 10_000
        case .below12500: return 12_500
        }
    }

    public var range: ClosedRange<Int> {
        switch self {
        case .below7k: return 6_500...6_999
        case .below10k: return 9_500...9_999
        case .below12500: return 12_000...12_499
        }
    }

    public static func current(steps: Int) -> NudgeZone? {
        NudgeZone.allCases.first(where: { $0.range.contains(steps) })
    }
}
