import Foundation

/// The workout that earned the 8-point "workout green" state, and the
/// metrics that qualified it. Shown in the iOS Today section so the user
/// can see *why* the app is green rather than just a green flag.
public struct WorkoutGreenDetail: Equatable, Sendable, Codable {
    public let durationMinutes: Double
    public let avgHR: Double       // bpm
    public let maxHR: Double       // bpm (220 - age at the time)
    public let workoutName: String?

    public init(durationMinutes: Double, avgHR: Double, maxHR: Double, workoutName: String? = nil) {
        self.durationMinutes = durationMinutes
        self.avgHR = avgHR
        self.maxHR = maxHR
        self.workoutName = workoutName
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

    /// Convenience for tests and call sites that only care about the boolean.
    public var workoutGreen: Bool { workoutDetail != nil }

    public var tier: StepTier { StepTier.from(steps: steps) }

    public var nudgeZone: NudgeZone? { NudgeZone.current(steps: steps) }

    public var isGreen: Bool { tier == .green || workoutGreen }

    public var effectiveTier: StepTier { workoutGreen ? .green : tier }

    /// Compute effective points for display: max of step-points and workout 8 (if applicable).
    public var points: Int {
        let stepPoints = VitalityPoints.fromSteps(steps)
        return workoutGreen ? max(stepPoints, 8) : stepPoints
    }
}
