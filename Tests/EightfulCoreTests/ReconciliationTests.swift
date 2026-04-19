import XCTest
@testable import EightfulCore

final class ReconciliationTests: XCTestCase {
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        return c
    }()

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset,
                      to: calendar.date(from: DateComponents(year: 2026, month: 4, day: 13))!)!
    }

    private func entry(dayOffset: Int, steps: Int, workoutGreen: Bool = false, reported: Int? = nil) -> ReconciliationEntry {
        ReconciliationEntry(
            date: day(dayOffset),
            calculated: DayState(steps: steps, workoutGreen: workoutGreen, timestamp: day(dayOffset)),
            reported: reported
        )
    }

    func testEntryStatusMatched() {
        let e = entry(dayOffset: 0, steps: 11_000, reported: 5)
        XCTAssertEqual(e.status, .matched)
        XCTAssertEqual(e.diff, 0)
    }

    func testEntryStatusMismatched() {
        let e = entry(dayOffset: 0, steps: 11_000, reported: 3)
        XCTAssertEqual(e.status, .mismatched)
        XCTAssertEqual(e.diff, 2)
    }

    func testEntryStatusPending() {
        let e = entry(dayOffset: 0, steps: 11_000, reported: nil)
        XCTAssertEqual(e.status, .pending)
        XCTAssertNil(e.diff)
    }

    func testWeekTotalsWithAllReported() {
        let week = WeekReconciliation(weekStart: day(0), days: [
            entry(dayOffset: 0, steps: 8_000, reported: 3),
            entry(dayOffset: 1, steps: 11_000, reported: 5),
            entry(dayOffset: 2, steps: 13_000, reported: 8),
            entry(dayOffset: 3, steps: 3_000, workoutGreen: true, reported: 8),
            entry(dayOffset: 4, steps: 5_000, reported: 0),
            entry(dayOffset: 5, steps: 9_500, reported: 3),
            entry(dayOffset: 6, steps: 13_000, reported: 8),
        ])
        XCTAssertEqual(week.calculatedTotal, 3 + 5 + 8 + 8 + 0 + 3 + 8)
        XCTAssertEqual(week.reportedTotal, 35)
        XCTAssertEqual(week.matchedCount, 7)
    }

    func testWeekTotalsWhenPending() {
        let week = WeekReconciliation(weekStart: day(0), days: [
            entry(dayOffset: 0, steps: 8_000, reported: 3),
            entry(dayOffset: 1, steps: 11_000, reported: nil),
        ])
        XCTAssertNil(week.reportedTotal)
        XCTAssertEqual(week.pendingCount, 1)
        XCTAssertEqual(week.matchedCount, 1)
    }

    // MARK: - Pattern detection

    func testPatternAllMatched() {
        let days = [
            entry(dayOffset: 0, steps: 8_000, reported: 3),
            entry(dayOffset: 1, steps: 11_000, reported: 5),
            entry(dayOffset: 2, steps: 13_000, reported: 8),
        ]
        XCTAssertEqual(Pattern.detect(in: days), .allMatched)
    }

    func testPatternInsufficientData() {
        let days = [
            entry(dayOffset: 0, steps: 8_000, reported: nil),
            entry(dayOffset: 1, steps: 11_000, reported: nil),
        ]
        XCTAssertEqual(Pattern.detect(in: days), .insufficientData)
    }

    func testPatternCalculatedHigher() {
        // 3 mismatches all with calculated > reported
        let days = [
            entry(dayOffset: 0, steps: 11_000, reported: 3),
            entry(dayOffset: 1, steps: 11_000, reported: 3),
            entry(dayOffset: 2, steps: 13_000, reported: 5),
        ]
        if case .calculatedSystematicallyHigher = Pattern.detect(in: days) { return }
        XCTFail("expected calculatedSystematicallyHigher")
    }

    func testPatternCalculatedLower() {
        let days = [
            entry(dayOffset: 0, steps: 8_000, reported: 5),
            entry(dayOffset: 1, steps: 11_000, reported: 8),
            entry(dayOffset: 2, steps: 8_000, reported: 5),
        ]
        if case .calculatedSystematicallyLower = Pattern.detect(in: days) { return }
        XCTFail("expected calculatedSystematicallyLower")
    }

    func testPatternMixed() {
        let days = [
            entry(dayOffset: 0, steps: 11_000, reported: 3),   // calc higher
            entry(dayOffset: 1, steps: 8_000, reported: 5),    // calc lower
            entry(dayOffset: 2, steps: 13_000, reported: 5),   // calc higher
        ]
        XCTAssertEqual(Pattern.detect(in: days), .mixed)
    }

    func testPatternTooFewMismatchesIsNone() {
        // 1 or 2 mismatches isn't enough signal.
        let days = [
            entry(dayOffset: 0, steps: 8_000, reported: 3),
            entry(dayOffset: 1, steps: 11_000, reported: 5),
            entry(dayOffset: 2, steps: 13_000, reported: 5), // mismatched
            entry(dayOffset: 3, steps: 8_000, reported: 3),
            entry(dayOffset: 4, steps: 13_000, reported: 8),
        ]
        XCTAssertEqual(Pattern.detect(in: days), .none)
    }
}
