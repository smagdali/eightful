import HealthKit

/// Human-readable name for the most common workout types. Anything not in
/// this list falls back to "Workout" rather than Apple's camelCase raw value.
extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running:              return "Running"
        case .walking:              return "Walking"
        case .cycling:              return "Cycling"
        case .swimming:             return "Swimming"
        case .hiking:               return "Hiking"
        case .functionalStrengthTraining,
             .traditionalStrengthTraining,
             .coreTraining,
             .mixedCardio,
             .highIntensityIntervalTraining:
                                     return "HIIT"
        case .yoga:                 return "Yoga"
        case .pilates:              return "Pilates"
        case .dance:                return "Dance"
        case .rowing:               return "Rowing"
        case .elliptical:           return "Elliptical"
        case .stairClimbing:        return "Stairs"
        case .stairs:               return "Stairs"
        case .kickboxing,
             .boxing,
             .martialArts:          return "Martial arts"
        case .crossTraining:        return "Cross-training"
        default:                    return "Workout"
        }
    }
}
