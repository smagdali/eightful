import Foundation

public struct DayState: Equatable, Sendable, Codable {
    public let steps: Int
    public let workoutGreen: Bool
    public let timestamp: Date

    public init(steps: Int, workoutGreen: Bool, timestamp: Date = Date()) {
        self.steps = steps
        self.workoutGreen = workoutGreen
        self.timestamp = timestamp
    }

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
