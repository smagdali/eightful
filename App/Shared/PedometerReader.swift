import Foundation
import CoreMotion

/// Real-time step count via CoreMotion. Much lower lag than HealthKit on the wrist-worn
/// device because it reads the motion coprocessor directly instead of the persisted
/// HealthKit store (which batches sample writes).
public final class PedometerReader {
    public static let shared = PedometerReader()

    private let pedometer = CMPedometer()
    private var isStreaming = false

    public var isAvailable: Bool { CMPedometer.isStepCountingAvailable() }

    /// One-shot: today's step count from local midnight to now.
    public func stepsToday(calendar: Calendar = .current, now: Date = Date()) async throws -> Int {
        guard isAvailable else { return 0 }
        let start = calendar.startOfDay(for: now)
        return try await withCheckedThrowingContinuation { cont in
            pedometer.queryPedometerData(from: start, to: now) { data, error in
                if let error { cont.resume(throwing: error); return }
                cont.resume(returning: data?.numberOfSteps.intValue ?? 0)
            }
        }
    }

    /// Steps for an arbitrary date range. CMPedometer only goes back 7 days.
    public func steps(from start: Date, to end: Date) async throws -> Int {
        guard isAvailable else { return 0 }
        return try await withCheckedThrowingContinuation { cont in
            pedometer.queryPedometerData(from: start, to: end) { data, error in
                if let error { cont.resume(throwing: error); return }
                cont.resume(returning: data?.numberOfSteps.intValue ?? 0)
            }
        }
    }

    /// Push-style live updates. `onUpdate` is called as the user takes steps.
    /// `from` is typically local midnight to get today's running total.
    public func startLiveUpdates(from date: Date, onUpdate: @escaping @Sendable (Int) -> Void) {
        guard isAvailable, !isStreaming else { return }
        isStreaming = true
        pedometer.startUpdates(from: date) { data, _ in
            guard let data else { return }
            onUpdate(data.numberOfSteps.intValue)
        }
    }

    public func stopLiveUpdates() {
        pedometer.stopUpdates()
        isStreaming = false
    }
}
