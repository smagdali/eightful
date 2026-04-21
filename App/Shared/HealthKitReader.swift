import Foundation
import HealthKit
import EightfulCore

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

    /// Sum of step count samples between two dates.
    public func steps(from start: Date, to end: Date) async throws -> Int {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
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

    /// Convenience: sum of step count samples from local midnight to `now`.
    public func stepsToday(calendar: Calendar = .current, now: Date = Date()) async throws -> Int {
        try await steps(from: calendar.startOfDay(for: now), to: now)
    }

    /// Returns the first qualifying workout's details (8 Vitality points) in
    /// the range, or nil if none qualify.
    public func qualifyingWorkoutGreen(maxHR: Double, from start: Date, to end: Date) async throws -> WorkoutGreenDetail? {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

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
                return WorkoutGreenDetail(
                    durationMinutes: durationMinutes,
                    avgHR: avgHR,
                    maxHR: maxHR,
                    workoutName: workout.workoutActivityType.name
                )
            }
        }
        return nil
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
        try await dayState(on: now, settings: settings, calendar: calendar, endOverride: now)
    }

    /// Compute a historical `DayState` for any calendar day.
    /// - Parameter day: any time on the day of interest; we normalise to start-of-day.
    /// - Parameter endOverride: upper bound. Nil uses end-of-day. For "today" we pass `now`.
    public func dayState(on day: Date, settings: AppSettings, calendar: Calendar = .current, endOverride: Date? = nil) async throws -> DayState {
        let startOfDay = calendar.startOfDay(for: day)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        let end = endOverride ?? endOfDay
        let isToday = calendar.isDateInToday(day)

        // Prefer CoreMotion for today's live count ON THE WATCH — HealthKit lags
        // behind the motion coprocessor by minutes. On iPhone we keep HealthKit
        // because the phone may be on a desk (CMPedometer = 0) while the watch
        // is actually the counting device — HealthKit merges those samples.
        //
        // If CoreMotion errors transiently (low-power / sensor service blip) we
        // fall back to HealthKit rather than silently reporting zero. A genuine
        // zero should only appear when BOTH sources agree.
        let steps: Int
        #if os(watchOS)
        if isToday, PedometerReader.shared.isAvailable {
            do {
                steps = try await PedometerReader.shared.steps(from: startOfDay, to: end)
            } catch {
                steps = try await self.steps(from: startOfDay, to: end)
            }
        } else {
            steps = try await self.steps(from: startOfDay, to: end)
        }
        #else
        steps = try await self.steps(from: startOfDay, to: end)
        #endif

        // Max HR is computed as-of the day being scored (more accurate if the DOB boundary falls within the range).
        let dob = settings.dobOverride ?? dateOfBirth(calendar: calendar)
        let maxHR: Double = dob.map { MaxHeartRate.from(dateOfBirth: $0, now: startOfDay, calendar: calendar) } ?? 0

        let workoutDetail: WorkoutGreenDetail?
        if maxHR > 0 {
            workoutDetail = (try? await qualifyingWorkoutGreen(maxHR: maxHR, from: startOfDay, to: end)) ?? nil
        } else {
            workoutDetail = nil
        }

        return DayState(steps: steps, workoutDetail: workoutDetail, timestamp: startOfDay)
    }

    /// Build reconciliation entries for the week containing `date` (Monday -> Sunday, local calendar).
    public func weekReconciliation(
        containing date: Date,
        settings: AppSettings,
        reported: (Date) -> Int? = { _ in nil },
        calendar: Calendar = .current
    ) async -> WeekReconciliation {
        var cal = calendar
        cal.firstWeekday = 2 // Monday
        let weekStart: Date = {
            let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            return cal.date(from: comps) ?? cal.startOfDay(for: date)
        }()
        var entries: [ReconciliationEntry] = []
        for offset in 0..<7 {
            guard let d = cal.date(byAdding: .day, value: offset, to: weekStart) else { continue }
            let state = (try? await dayState(on: d, settings: settings, calendar: cal)) ?? DayState(steps: 0, workoutGreen: false, timestamp: cal.startOfDay(for: d))
            entries.append(ReconciliationEntry(date: cal.startOfDay(for: d), calculated: state, reported: reported(d)))
        }
        return WeekReconciliation(weekStart: weekStart, days: entries)
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
