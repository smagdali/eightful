import Foundation

/// One day of reconciliation between what StepsToEight calculated from HealthKit
/// and what Vitality's Member Zone reports. Calculated side is always present
/// (we have HealthKit); reported side is optional because Vitality's feed lags
/// and some days may still be pending when the user checks.
public struct ReconciliationEntry: Equatable, Sendable, Codable {
    public let date: Date               // start-of-day, local calendar
    public let calculated: DayState     // what we saw in HealthKit
    public let reported: Int?           // what Vitality reports. nil = not yet entered / still pending

    public init(date: Date, calculated: DayState, reported: Int? = nil) {
        self.date = date
        self.calculated = calculated
        self.reported = reported
    }

    public enum Status: String, Sendable, Codable {
        case pending      // no reported value yet
        case matched      // calculated == reported
        case mismatched   // calculated != reported
    }

    public var status: Status {
        guard let reported else { return .pending }
        return reported == calculated.points ? .matched : .mismatched
    }

    public var diff: Int? {
        guard let reported else { return nil }
        return calculated.points - reported
    }
}

/// A week of reconciliation. `days` is expected length 7, ordered oldest -> newest.
public struct WeekReconciliation: Equatable, Sendable, Codable {
    public let weekStart: Date        // Monday of the week, start-of-day
    public let days: [ReconciliationEntry]

    public init(weekStart: Date, days: [ReconciliationEntry]) {
        self.weekStart = weekStart
        self.days = days
    }

    public var calculatedTotal: Int {
        days.map(\.calculated.points).reduce(0, +)
    }

    public var reportedTotal: Int? {
        // If any reported value is missing, we can't meaningfully total.
        let reports = days.compactMap(\.reported)
        return reports.count == days.count ? reports.reduce(0, +) : nil
    }

    public var matchedCount: Int { days.filter { $0.status == .matched }.count }
    public var mismatchedCount: Int { days.filter { $0.status == .mismatched }.count }
    public var pendingCount: Int { days.filter { $0.status == .pending }.count }

    public var pattern: Pattern { Pattern.detect(in: days) }
}

/// A heuristic read on whether mismatches are systematic (and so point to a config
/// issue we can fix) rather than random lag / sync noise.
public enum Pattern: Equatable, Sendable {
    case none
    case insufficientData
    case allMatched
    case calculatedSystematicallyHigher(averageDelta: Double)
    case calculatedSystematicallyLower(averageDelta: Double)
    case mixed

    public static func detect(in days: [ReconciliationEntry]) -> Pattern {
        let settled = days.filter { $0.status != .pending }
        if settled.isEmpty { return .insufficientData }
        let mismatches = settled.filter { $0.status == .mismatched }
        if mismatches.isEmpty { return .allMatched }
        if mismatches.count < 3 { return .none }

        let diffs = mismatches.compactMap(\.diff)
        let allPositive = diffs.allSatisfy { $0 > 0 }
        let allNegative = diffs.allSatisfy { $0 < 0 }
        let avg = Double(diffs.reduce(0, +)) / Double(diffs.count)
        if allPositive { return .calculatedSystematicallyHigher(averageDelta: avg) }
        if allNegative { return .calculatedSystematicallyLower(averageDelta: abs(avg)) }
        return .mixed
    }

    public var humanReadable: String {
        switch self {
        case .none:
            return "No systematic pattern yet."
        case .insufficientData:
            return "Enter Vitality's reported points to see a comparison."
        case .allMatched:
            return "All settled days match. Calculation is in sync with Vitality."
        case .calculatedSystematicallyHigher(let avg):
            return String(format: "Calculated points run %.1f higher than Vitality on average. Likely cause: max HR threshold too low (DOB wrong?) or step thresholds misaligned.", avg)
        case .calculatedSystematicallyLower(let avg):
            return String(format: "Calculated points run %.1f lower than Vitality on average. Likely cause: missing workouts, DOB giving an inflated max HR, or HR samples not captured.", avg)
        case .mixed:
            return "Mismatches go in both directions. Likely cause: sync lag or timezone handling rather than a calculation bug."
        }
    }
}
