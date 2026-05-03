import Foundation

public struct HeartRateSample: Equatable, Sendable {
    public let timestamp: Date
    public let bpm: Double
    public init(timestamp: Date, bpm: Double) {
        self.timestamp = timestamp
        self.bpm = bpm
    }
}

public enum VitalityPoints {
    public static func fromSteps(_ steps: Int) -> Int {
        switch steps {
        case ..<7_000: return 0
        case 7_000..<10_000: return 3
        case 10_000..<12_500: return 5
        default: return 8
        }
    }

    /// Vitality requires HR to stay at-or-above the threshold for a *continuous*
    /// period (not a workout-wide average). We find the longest continuous window
    /// of samples ≥ each threshold and award:
    ///   - 30 min @ ≥70% max HR  => 8 pts
    ///   - 60 min @ ≥60% max HR  => 8 pts
    ///   - 30 min @ ≥60% max HR  => 5 pts
    /// Using the workout-wide average mis-scored workouts where a hard 30-min
    /// block was bracketed by warm-up / cool-down (avg dropped below 70% so we
    /// returned 5; Vitality saw the continuous block and returned 8).
    public static func fromWorkout(samples: [HeartRateSample], maxHR: Double) -> Int {
        guard maxHR > 0 else { return 0 }
        let longest70 = longestContinuousWindow(samples: samples, threshold: maxHR * 0.70)
        let longest60 = longestContinuousWindow(samples: samples, threshold: maxHR * 0.60)
        let thirty: TimeInterval = 30 * 60
        let sixty: TimeInterval = 60 * 60
        if longest70 >= thirty { return 8 }
        if longest60 >= sixty  { return 8 }
        if longest60 >= thirty { return 5 }
        return 0
    }

    /// Longest stretch where consecutive samples all meet `threshold`.
    /// A gap larger than `maxGap` between consecutive qualifying samples breaks
    /// the run - we can't claim continuity across a missing-data window.
    /// Window length is measured first-qualifying-sample → last-qualifying-sample.
    static func longestContinuousWindow(samples: [HeartRateSample], threshold: Double, maxGap: TimeInterval = 60) -> TimeInterval {
        var longest: TimeInterval = 0
        var runStart: Date?
        var runLast: Date?
        for s in samples {
            if s.bpm >= threshold {
                if let last = runLast, s.timestamp.timeIntervalSince(last) > maxGap {
                    runStart = s.timestamp
                } else if runStart == nil {
                    runStart = s.timestamp
                }
                runLast = s.timestamp
                if let start = runStart {
                    longest = max(longest, s.timestamp.timeIntervalSince(start))
                }
            } else {
                runStart = nil
                runLast = nil
            }
        }
        return longest
    }
}
