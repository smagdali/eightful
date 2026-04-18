import Foundation
import HealthKit
import StepsToEightCore

/// Reads today's step count and workout scoring from HealthKit.
/// Used by both the iOS app (for notifications) and the watchOS app/complication (for rendering).
public final class HealthKitReader {
    public static let shared = HealthKitReader()

    private let store = HKHealthStore()

    public enum ReadError: Error {
        case notAvailable
        case notAuthorized
    }

    public var isHealthDataAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    public var readTypes: Set<HKObjectType> {
        var set: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.workoutType(),
        ]
        if let dob = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) {
            set.insert(dob)
        }
        return set
    }

    public func requestAuthorization() async throws {
        guard isHealthDataAvailable else { throw ReadError.notAvailable }
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    public func dateOfBirth(calendar: Calendar = .current) -> Date? {
        guard let components = try? store.dateOfBirthComponents() else { return nil }
        return calendar.date(from: components)
    }

    /// Sum of step count samples for today (midnight -> now, local calendar).
    public func stepsToday(calendar: Calendar = .current, now: Date = Date()) async throws -> Int {
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

        return try await withCheckedThrowingContinuation { cont in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let error {
                    cont.resume(throwing: error)
                    return
                }
                let count = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                cont.resume(returning: Int(count))
            }
            self.store.execute(query)
        }
    }

    /// Scans today's workouts; returns true if any single workout earns 8 Vitality points.
    public func workoutGreenToday(maxHR: Double, calendar: Calendar = .current, now: Date = Date()) async throws -> Bool {
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let workouts: [HKWorkout] = try await withCheckedThrowingContinuation { cont in
            let q = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error { cont.resume(throwing: error); return }
                cont.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            self.store.execute(q)
        }

        for workout in workouts {
            let durationMinutes = workout.duration / 60.0
            if durationMinutes < 30 { continue }
            let hr = (try? await averageHeartRate(for: workout)) ?? nil
            guard let avgHR = hr else { continue }
            if VitalityPoints.fromWorkout(durationMinutes: durationMinutes, avgHR: avgHR, maxHR: maxHR) == 8 {
                return true
            }
        }
        return false
    }

    /// Average heart rate (bpm) across the workout's time range.
    public func averageHeartRate(for workout: HKWorkout) async throws -> Double? {
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { cont in
            let q = HKStatisticsQuery(quantityType: hrType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, stats, error in
                if let error { cont.resume(throwing: error); return }
                let bpm = stats?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                cont.resume(returning: bpm)
            }
            self.store.execute(q)
        }
    }

    /// Compute today's `DayState` by fetching steps + workout-green evaluation.
    public func currentDayState(settings: AppSettings, calendar: Calendar = .current, now: Date = Date()) async throws -> DayState {
        let steps = try await stepsToday(calendar: calendar, now: now)

        let dob = settings.dobOverride ?? dateOfBirth(calendar: calendar)
        let maxHR: Double = dob.map { MaxHeartRate.from(dateOfBirth: $0, now: now, calendar: calendar) } ?? 0

        let workoutGreen: Bool
        if maxHR > 0 {
            workoutGreen = (try? await workoutGreenToday(maxHR: maxHR, calendar: calendar, now: now)) ?? false
        } else {
            workoutGreen = false
        }

        return DayState(steps: steps, workoutGreen: workoutGreen, timestamp: now)
    }

    /// Long-lived observer. Caller retains the query; call `store.stop(query)` when done.
    public func observeUpdates(_ handler: @escaping () -> Void) -> HKObserverQuery {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { _, completionHandler, error in
            if error == nil { handler() }
            completionHandler()
        }
        store.execute(query)

        // Also set up background delivery on iOS (watchOS ignores this).
        store.enableBackgroundDelivery(for: stepType, frequency: .immediate, withCompletion: { _, _ in })
        return query
    }
}
