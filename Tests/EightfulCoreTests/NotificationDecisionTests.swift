import XCTest
@testable import EightfulCore

final class NotificationDecisionTests: XCTestCase {
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        return c
    }()

    private func date(_ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 4, day: 18, hour: hour, minute: minute))!
    }

    private func historyEmpty(at now: Date) -> NotificationHistory {
        NotificationHistory.empty(for: now, calendar: calendar)
    }

    // MARK: - Pre-window

    func testBeforeNudgeWindowSuppresses() {
        let state = DayState(steps: 9_600, workoutGreen: false, timestamp: date(14))
        let action = NotificationDecision.evaluate(
            state: state,
            now: date(14),
            settings: .default,
            history: historyEmpty(at: date(14)),
            calendar: calendar
        )
        XCTAssertEqual(action, .suppress)
    }

    func testNotificationsDisabledSuppresses() {
        let state = DayState(steps: 9_600, workoutGreen: false, timestamp: date(20))
        var settings = AppSettings.default
        settings.notificationsEnabled = false
        let action = NotificationDecision.evaluate(
            state: state,
            now: date(20),
            settings: settings,
            history: historyEmpty(at: date(20)),
            calendar: calendar
        )
        XCTAssertEqual(action, .suppress)
    }

    // MARK: - Nudge window (7pm-8pm)

    func testNudgeAt7PmWhenInBelow10kZone() {
        let state = DayState(steps: 9_600, workoutGreen: false, timestamp: date(19, 15))
        let action = NotificationDecision.evaluate(
            state: state,
            now: date(19, 15),
            settings: .default,
            history: historyEmpty(at: date(19, 15)),
            calendar: calendar
        )
        XCTAssertEqual(action, .nudge(.below10k))
    }

    func testNudgeAt7PmWhenInBelow7kZone() {
        let state = DayState(steps: 6_700, workoutGreen: false, timestamp: date(19, 30))
        let action = NotificationDecision.evaluate(
            state: state,
            now: date(19, 30),
            settings: .default,
            history: historyEmpty(at: date(19, 30)),
            calendar: calendar
        )
        XCTAssertEqual(action, .nudge(.below7k))
    }

    func testNoNudgeForBelow12500ZoneInPreReportWindow() {
        // User wanted 12,000-12,499 nudge at 8pm only
        let state = DayState(steps: 12_200, workoutGreen: false, timestamp: date(19, 30))
        let action = NotificationDecision.evaluate(
            state: state,
            now: date(19, 30),
            settings: .default,
            history: historyEmpty(at: date(19, 30)),
            calendar: calendar
        )
        XCTAssertEqual(action, .suppress)
    }

    func testNudgeSuppressedIfAlreadyFired() {
        let state = DayState(steps: 9_600, workoutGreen: false, timestamp: date(19, 30))
        var history = historyEmpty(at: date(19, 30))
        history = history.markingNudged(.below10k)
        let action = NotificationDecision.evaluate(
            state: state,
            now: date(19, 30),
            settings: .default,
            history: history,
            calendar: calendar
        )
        XCTAssertEqual(action, .suppress)
    }

    func testNoNudgeOutsideZone() {
        let state = DayState(steps: 8_500, workoutGreen: false, timestamp: date(19, 30))
        let action = NotificationDecision.evaluate(
            state: state,
            now: date(19, 30),
            settings: .default,
            history: historyEmpty(at: date(19, 30)),
            calendar: calendar
        )
        XCTAssertEqual(action, .suppress)
    }

    // MARK: - Report time (8pm)

    func testReportAt8PmForNonGreenNonZone() {
        let state = DayState(steps: 8_200, workoutGreen: false, timestamp: date(20))
        let action = NotificationDecision.evaluate(
            state: state,
            now: date(20),
            settings: .default,
            history: historyEmpty(at: date(20)),
            calendar: calendar
        )
        XCTAssertEqual(action, .report(state))
    }

    func testSuppressAt8PmWhenStepsGreen() {
        let state = DayState(steps: 13_000, workoutGreen: false, timestamp: date(20))
        let action = NotificationDecision.evaluate(
            state: state,
            now: date(20),
            settings: .default,
            history: historyEmpty(at: date(20)),
            calendar: calendar
        )
        XCTAssertEqual(action, .suppress)
    }

    func testSuppressAt8PmWhenWorkoutGreen() {
        let state = DayState(steps: 8_000, workoutGreen: true, timestamp: date(20))
        let action = NotificationDecision.evaluate(
            state: state,
            now: date(20),
            settings: .default,
            history: historyEmpty(at: date(20)),
            calendar: calendar
        )
        XCTAssertEqual(action, .suppress)
    }

    func testNudgeAt8PmOverridesGreenSuppressionForBelow12500() {
        // User explicitly wanted: nudge overrides green suppression in 12,000-12,499
        let state = DayState(steps: 12_200, workoutGreen: true, timestamp: date(20))
        let action = NotificationDecision.evaluate(
            state: state,
            now: date(20),
            settings: .default,
            history: historyEmpty(at: date(20)),
            calendar: calendar
        )
        XCTAssertEqual(action, .nudge(.below12500))
    }

    func testNudgeAt8PmOverridesForBelow10kZone() {
        let state = DayState(steps: 9_800, workoutGreen: true, timestamp: date(20))
        let action = NotificationDecision.evaluate(
            state: state,
            now: date(20),
            settings: .default,
            history: historyEmpty(at: date(20)),
            calendar: calendar
        )
        XCTAssertEqual(action, .nudge(.below10k))
    }

    func testReportSuppressedIfAlreadyFired() {
        let state = DayState(steps: 8_200, workoutGreen: false, timestamp: date(20, 30))
        var history = historyEmpty(at: date(20, 30))
        history = history.markingReported()
        let action = NotificationDecision.evaluate(
            state: state,
            now: date(20, 30),
            settings: .default,
            history: history,
            calendar: calendar
        )
        XCTAssertEqual(action, .suppress)
    }

    // MARK: - Rollover

    func testHistoryRollsOverAcrossMidnight() {
        let yesterday = calendar.date(from: DateComponents(year: 2026, month: 4, day: 17, hour: 21))!
        let today = date(10)
        var history = NotificationHistory.empty(for: yesterday, calendar: calendar)
        history = history.markingReported()
        let rolled = history.rolledOver(to: today, calendar: calendar)
        XCTAssertFalse(rolled.reportedToday)
        XCTAssertEqual(rolled.day, calendar.startOfDay(for: today))
    }
}
