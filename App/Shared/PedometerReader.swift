import Foundation
import CoreMotion

/// Real-time step count via CoreMotion. Much lower lag than HealthKit on the wrist-worn
/// device because it reads the motion coprocessor directly instead of the persisted
/// HealthKit store (which batches sample writes).
public final class PedometerReader {
    public static let shared = PedometerReader()

    private let pedometer = CMPedometer()
    private var isStreaming = false

    public enum ReadError: Error {
        /// CoreMotion returned nil data with no error — usually means the sensor
        /// service is briefly unavailable (device sleeping, low-power, restart).
        /// Callers should treat this as "unknown", not as "zero".
        case noData
        case unavailable
    }

    public var isAvailable: Bool { CMPedometer.isStepCountingAvailable() }

    /// One-shot: today's step count from local midnight to now.
    public func stepsToday(calendar: Calendar = .current, now: Date = Date()) async throws -> Int {
        try await steps(from: calendar.startOfDay(for: now), to: now)
    }

    /// Steps for an arbitrary date range. CMPedometer only goes back 7 days.
    public func steps(from start: Date, to end: Date) async throws -> Int {
        guard isAvailable else { throw ReadError.unavailable }
        return try await withCheckedThrowingContinuation { cont in
            pedometer.queryPedometerData(from: start, to: end) { data, error in
                if let error { cont.resume(throwing: error); return }
                guard let data else {
                    cont.resume(throwing: ReadError.noData)
                    return
                }
                cont.resume(returning: data.numberOfSteps.intValue)
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
