import Foundation

/// The best Vitality-scoring workout for the day and the metrics that
/// qualified it. `points` is 5 (30 min @ 60% max HR) or 8 (30 min @ 70%
/// or 60 min @ 60%). Shown in the iOS Today section so the user can see
/// *why* a workout earned points rather than just a flag.
public struct WorkoutGreenDetail: Equatable, Sendable, Codable {
    public let durationMinutes: Double
    public let avgHR: Double       // bpm
    public let maxHR: Double       // bpm (220 - age at the time)
    public let workoutName: String?
    public let points: Int         // 5 or 8

    public init(durationMinutes: Double, avgHR: Double, maxHR: Double, workoutName: String? = nil, points: Int = 8) {
        self.durationMinutes = durationMinutes
        self.avgHR = avgHR
        self.maxHR = maxHR
        self.workoutName = workoutName
        self.points = points
    }

    public var percentOfMax: Double {
        guard maxHR > 0 else { return 0 }
        return (avgHR / maxHR) * 100
    }
}

public struct DayState: Equatable, Sendable, Codable {
    public let steps: Int
    public let workoutDetail: WorkoutGreenDetail?
    public let timestamp: Date

    public init(steps: Int, workoutGreen: Bool, timestamp: Date = Date()) {
        self.steps = steps
        self.workoutDetail = workoutGreen ? WorkoutGreenDetail(durationMinutes: 0, avgHR: 0, maxHR: 0) : nil
        self.timestamp = timestamp
    }

    public init(steps: Int, workoutDetail: WorkoutGreenDetail?, timestamp: Date = Date()) {
        self.steps = steps
        self.workoutDetail = workoutDetail
        self.timestamp = timestamp
    }

    /// True only when a workout earned the full 8 points - drives the
    /// "green via workout" visual treatments. A 5-pt workout still
    /// contributes to `points` but does not flip this flag.
    public var workoutGreen: Bool { (workoutDetail?.points ?? 0) >= 8 }

    public var tier: StepTier { StepTier.from(steps: steps) }

    public var nudgeZone: NudgeZone? { NudgeZone.current(steps: steps) }

    public var isGreen: Bool { tier == .green || workoutGreen }

    public var effectiveTier: StepTier { workoutGreen ? .green : tier }

    /// Per Vitality: only one activity per day counts, the highest-scoring one.
    /// We take max(steps-points, workout-points) where workout-points is 0/5/8.
    public var points: Int {
        max(VitalityPoints.fromSteps(steps), workoutDetail?.points ?? 0)
    }
}
