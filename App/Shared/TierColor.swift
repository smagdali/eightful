import SwiftUI
import EightfulCore

public extension StepTier {
    /// Vitality-points tier colour (used in contexts where we surface earned-points
    /// state, like the Compare tab). The big step count on watch/complication uses
    /// `DisplayColor` instead, which flips to red in nudge zones.
    var color: Color {
        switch self {
        case .red:    return Color(red: 1.00, green: 0.25, blue: 0.25)
        case .orange: return Color(red: 1.00, green: 0.60, blue: 0.10)
        case .yellow: return Color(red: 1.00, green: 0.90, blue: 0.10)
        case .green:  return Color(red: 0.20, green: 0.90, blue: 0.35)
        }
    }
}

public extension DisplayColor {
    /// Colour for the big step count display. White below any nudge zone, red
    /// inside a nudge zone (signalling "push now"), then orange/yellow/green
    /// as points are banked.
    var color: Color {
        switch self {
        case .white:  return .white
        case .red:    return Color(red: 1.00, green: 0.25, blue: 0.25)
        case .orange: return Color(red: 1.00, green: 0.60, blue: 0.10)
        case .yellow: return Color(red: 1.00, green: 0.90, blue: 0.10)
        case .green:  return Color(red: 0.20, green: 0.90, blue: 0.35)
        }
    }
}
