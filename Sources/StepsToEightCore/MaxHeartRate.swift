import Foundation

public enum MaxHeartRate {
    public static func from(age: Int) -> Double {
        Double(max(0, 220 - age))
    }

    public static func from(dateOfBirth: Date, now: Date = Date(), calendar: Calendar = .current) -> Double {
        let years = calendar.dateComponents([.year], from: dateOfBirth, to: now).year ?? 0
        return from(age: years)
    }
}
