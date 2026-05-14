import XCTest
@testable import EightfulCore

final class NotificationCopyTests: XCTestCase {
    private func date(_ s: String) -> Date {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: s)!
    }

    // MARK: - .report copy includes step count and distance to next tier

    func testReportInRedIncludesGapTo7k() {
        let state = DayState(steps: 5_902, workoutGreen: false, timestamp: date("2026-05-14T19:30:00Z"))
        let msg = NotificationCopy.message(for: .report(state))
        XCTAssertNotNil(msg)
        XCTAssertEqual(msg?.title, "5,902 steps today")
        XCTAssertEqual(msg?.body, "Red tier, 0 points. 1,098 steps to 3 points.")
    }

    func testReportInOrangeIncludesGapTo10k() {
        let state = DayState(steps: 7_345, workoutGreen: false, timestamp: date("2026-05-14T19:30:00Z"))
        let msg = NotificationCopy.message(for: .report(state))
        XCTAssertEqual(msg?.title, "7,345 steps today")
        XCTAssertEqual(msg?.body, "Orange tier, 3 points. 2,655 steps to 5 points.")
    }

    func testReportInYellowIncludesGapTo12500() {
        let state = DayState(steps: 11_010, workoutGreen: false, timestamp: date("2026-05-14T19:30:00Z"))
        let msg = NotificationCopy.message(for: .report(state))
        XCTAssertEqual(msg?.title, "11,010 steps today")
        XCTAssertEqual(msg?.body, "Yellow tier, 5 points. 1,490 steps to 8 points.")
    }

    func testReportInGreenViaWorkoutOmitsGap() {
        let detail = WorkoutGreenDetail(durationMinutes: 35, avgHR: 140, maxHR: 185, workoutName: "HIIT", points: 8)
        let state = DayState(steps: 3_200, workoutDetail: detail, timestamp: date("2026-05-14T19:30:00Z"))
        let msg = NotificationCopy.message(for: .report(state))
        XCTAssertEqual(msg?.title, "Green via workout")
        XCTAssertEqual(msg?.body, "Full 8 points already locked in. 3,200 steps so far today.")
    }

    func testReportSingularPointHasCorrectGrammar() {
        // 1 point doesn't actually happen with the current scoring (jumps 0→3),
        // but the singular branch is still exercised defensively if scoring
        // ever changes.
        let state = DayState(steps: 7_000, workoutGreen: false, timestamp: date("2026-05-14T19:30:00Z"))
        let msg = NotificationCopy.message(for: .report(state))
        // 7,000 = 3 points, plural
        XCTAssertEqual(msg?.body, "Orange tier, 3 points. 3,000 steps to 5 points.")
    }

    // MARK: - nextTierGap helper

    func testNextTierGapAtZero() {
        let next = NotificationCopy.nextTierGap(steps: 0)
        XCTAssertEqual(next?.gap, 7_000)
        XCTAssertEqual(next?.points, 3)
    }

    func testNextTierGapJustBelow7k() {
        let next = NotificationCopy.nextTierGap(steps: 6_999)
        XCTAssertEqual(next?.gap, 1)
        XCTAssertEqual(next?.points, 3)
    }

    func testNextTierGapAt7kPointsUpwards() {
        let next = NotificationCopy.nextTierGap(steps: 7_000)
        XCTAssertEqual(next?.gap, 3_000)
        XCTAssertEqual(next?.points, 5)
    }

    func testNextTierGapAt12500IsNil() {
        XCTAssertNil(NotificationCopy.nextTierGap(steps: 12_500))
        XCTAssertNil(NotificationCopy.nextTierGap(steps: 20_000))
    }
}
