import Foundation

/// What colour the big step count should be rendered in.
/// Distinct from `StepTier` (which maps to Vitality point awards) — `DisplayColor`
/// answers "what urgency state is the user in right now", which includes flipping
/// to red when in a nudge zone to signal "push now, a threshold is within reach".
public enum DisplayColor: String, Sendable, Equatable {
    case white   // <6,500 — no urgency yet
    case red     // in a nudge zone (500 short of 7k / 10k / 12.5k), push!
    case orange  // 7,000-9,499 — 3 pts earned
    case yellow  // 10,000-11,999 — 5 pts earned
    case green   // 12,500+ or workout-8pt — done
}

public extension DayState {
    var displayColor: DisplayColor {
        if workoutGreen { return .green }
        if NudgeZone.current(steps: steps) != nil { return .red }
        switch StepTier.from(steps: steps) {
        case .red:    return .white
        case .orange: return .orange
        case .yellow: return .yellow
        case .green:  return .green
        }
    }
}

public extension DayState {
    /// Returns true if moving from `old` to `self` crossed a tier boundary,
    /// a nudge zone boundary, or flipped the workout-green flag. Used to
    /// debounce complication reloads — we don't want to burn the widget's
    /// ~40-70/day reload budget on every 15-second step increment.
    func isMaterialChange(from old: DayState?) -> Bool {
        guard let old else { return true }
        if old.workoutGreen != workoutGreen { return true }
        if StepTier.from(steps: old.steps) != StepTier.from(steps: steps) { return true }
        if NudgeZone.current(steps: old.steps) != NudgeZone.current(steps: steps) { return true }
        return false
    }
}
