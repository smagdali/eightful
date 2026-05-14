import XCTest
@testable import EightfulCore

final class NotificationCopyTests: XCTestCase {
    private func date(_ s: String) -> Date {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: s)!
    }

    // MARK: - .report copy: single-line "X steps - Y points - Z more to N points"

    func testReportInRedIncludesGapTo7k() {
        let state = DayState(steps: 5_902, workoutGreen: false, timestamp: date("2026-05-14T19:30:00Z"))
        let msg = NotificationCopy.message(for: .report(state))
        XCTAssertNotNil(msg)
        XCTAssertEqual(msg?.title, "5,902 steps - 0 points - 1,098 more to 3 points")
        XCTAssertEqual(msg?.body, "")
    }

    func testReportInOrangeIncludesGapTo10k() {
        let state = DayState(steps: 7_345, workoutGreen: false, timestamp: date("2026-05-14T19:30:00Z"))
        let msg = NotificationCopy.message(for: .report(state))
        XCTAssertEqual(msg?.title, "7,345 steps - 3 points - 2,655 more to 5 points")
    }

    func testReportInYellowIncludesGapTo12500() {
        let state = DayState(steps: 11_010, workoutGreen: false, timestamp: date("2026-05-14T19:30:00Z"))
        let msg = NotificationCopy.message(for: .report(state))
        XCTAssertEqual(msg?.title, "11,010 steps - 5 points - 1,490 more to 8 points")
    }

    func testReportAtTopTierOmitsGap() {
        // Decision logic suppresses .report once isGreen is true (steps>=12,500
        // OR workoutGreen), but the copy guards against the case defensively.
        let state = DayState(steps: 13_500, workoutGreen: false, timestamp: date("2026-05-14T19:30:00Z"))
        let msg = NotificationCopy.message(for: .report(state))
        XCTAssertEqual(msg?.title, "13,500 steps - 8 points")
    }

    func testReportAt7kBoundary() {
        let state = DayState(steps: 7_000, workoutGreen: false, timestamp: date("2026-05-14T19:30:00Z"))
        let msg = NotificationCopy.message(for: .report(state))
        XCTAssertEqual(msg?.title, "7,000 steps - 3 points - 3,000 more to 5 points")
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
