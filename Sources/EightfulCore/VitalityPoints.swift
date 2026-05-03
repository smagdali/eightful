import Foundation

public enum VitalityPoints {
    public static func fromSteps(_ steps: Int) -> Int {
        switch steps {
        case ..<7_000: return 0
        case 7_000..<10_000: return 3
        case 10_000..<12_500: return 5
        default: return 8
        }
    }

    /// Scores a single workout per Vitality's heart-rate rules.
    /// Rules:
    ///   - 30 min @ avg HR >= 60% max HR  => 5 pts
    ///   - 60 min @ avg HR >= 60% max HR  => 8 pts
    ///   - 30 min @ avg HR >= 70% max HR  => 8 pts
    /// Points from a single workout are not summed with steps; daily cap is 8.
    public static func fromWorkout(durationMinutes: Double, avgHR: Double, maxHR: Double) -> Int {
        guard maxHR > 0, avgHR > 0, durationMinutes > 0 else { return 0 }
        let ratio = avgHR / maxHR
        let meets70 = ratio >= 0.70
        let meets60 = ratio >= 0.60

        if meets70 && durationMinutes >= 30 { return 8 }
        if meets60 && durationMinutes >= 60 { return 8 }
        if meets60 && durationMinutes >= 30 { return 5 }
        return 0
    }
}
