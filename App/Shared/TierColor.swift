import SwiftUI
import StepsToEightCore

public extension StepTier {
    var color: Color {
        switch self {
        case .red:    return Color(red: 0.85, green: 0.20, blue: 0.20)
        case .orange: return Color(red: 0.95, green: 0.55, blue: 0.15)
        case .yellow: return Color(red: 0.95, green: 0.80, blue: 0.10)
        case .green:  return Color(red: 0.20, green: 0.70, blue: 0.25)
        }
    }
}
