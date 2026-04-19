import SwiftUI
import StepsToEightCore

public extension StepTier {
    /// Punchy, full-saturation colours tuned to read clearly on a watch face in
    /// direct sunlight. Any softer and the complication fades against a photo face.
    var color: Color {
        switch self {
        case .red:    return Color(red: 1.00, green: 0.25, blue: 0.25)
        case .orange: return Color(red: 1.00, green: 0.60, blue: 0.10)
        case .yellow: return Color(red: 1.00, green: 0.90, blue: 0.10)
        case .green:  return Color(red: 0.20, green: 0.90, blue: 0.35)
        }
    }
}
