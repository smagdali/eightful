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

    func testBeforeNudgeTimeSuppresses() {
        let state = DayState(steps: 9_600, workoutGreen: false)
        let action = NotificationDecision.evaluate(
            state: state, now: date(14),
            settings: .default, history: historyEmpty(at: date(14)), calendar: calendar)
        XCTAssertEqual(action, .suppress)
    }

    func testNotificationsDisabledSuppresses() {
        let state = DayState(steps: 9_600, workoutGreen: false)
        var settings = AppSettings.default
        settings.notificationsEnabled = false
        let action = NotificationDecision.evaluate(
            state: state, now: date(20),
            settings: settings, history: historyEmpty(at: date(20)), calendar: calendar)
        XCTAssertEqual(action, .suppress)
    }

    // MARK: - At nudge time: zone wins over green

    func testNudgeWhenInBelow7kZone() {
        let state = DayState(steps: 6_700, workoutGreen: false)
        let action = NotificationDecision.evaluate(
            state: state, now: date(20),
            settings: .default, history: historyEmpty(at: date(20)), calendar: calendar)
        XCTAssertEqual(action, .nudge(.below7k))
    }

    func testNudgeWhenInBelow10kZone() {
        let state = DayState(steps: 9_600, workoutGreen: false)
        let action = NotificationDecision.evaluate(
            state: state, now: date(20),
            settings: .default, history: historyEmpty(at: date(20)), calendar: calendar)
        XCTAssertEqual(action, .nudge(.below10k))
    }

    func testNudgeWhenInBelow12500Zone() {
        let state = DayState(steps: 12_200, workoutGreen: false)
        let action = NotificationDecision.evaluate(
            state: state, now: date(20),
            settings: .default, history: historyEmpty(at: date(20)), calendar: calendar)
        XCTAssertEqual(action, .nudge(.below12500))
    }

    func testNudgeOverridesWorkoutGreen() {
        // Even though the user has 8pt via workout, 12,200 steps is so close
        // to 12,500 that it's worth the prompt (vitality-agnostic "push!" UX).
        let state = DayState(steps: 12_200, workoutGreen: true)
        let action = NotificationDecision.evaluate(
            state: state, now: date(20),
            settings: .default, history: historyEmpty(at: date(20)), calendar: calendar)
        XCTAssertEqual(action, .nudge(.below12500))
    }

    // MARK: - At nudge time: green suppresses when not in zone

    func testSuppressWhenStepsGreen() {
        let state = DayState(steps: 13_000, workoutGreen: false)
        let action = NotificationDecision.evaluate(
            state: state, now: date(20),
            settings: .default, history: historyEmpty(at: date(20)), calendar: calendar)
        XCTAssertEqual(action, .suppress)
    }

    func testSuppressWhenWorkoutGreenAndOutsideZone() {
        let state = DayState(steps: 8_000, workoutGreen: true)
        let action = NotificationDecision.evaluate(
            state: state, now: date(20),
            settings: .default, history: historyEmpty(at: date(20)), calendar: calendar)
        XCTAssertEqual(action, .suppress)
    }

    // MARK: - At nudge time: not green, not in zone → report

    func testReportWhenNotGreenNotInZone() {
        let state = DayState(steps: 8_200, workoutGreen: false)
        let action = NotificationDecision.evaluate(
            state: state, now: date(20),
            settings: .default, history: historyEmpty(at: date(20)), calendar: calendar)
        XCTAssertEqual(action, .report(state))
    }

    // MARK: - Already fired today

    func testSuppressedIfAlreadyReportedToday() {
        let state = DayState(steps: 8_200, workoutGreen: false)
        var history = historyEmpty(at: date(20, 30))
        history = history.markingReported()
        let action = NotificationDecision.evaluate(
            state: state, now: date(20, 30),
            settings: .default, history: history, calendar: calendar)
        XCTAssertEqual(action, .suppress)
    }

    // MARK: - Custom nudge time

    func testRespectsCustomNudgeTime() {
        let state = DayState(steps: 8_000, workoutGreen: false)
        var settings = AppSettings.default
        settings.nudgeTime = TimeOfDay(hour: 18, minute: 30)

        // 18:00 — too early
        XCTAssertEqual(
            NotificationDecision.evaluate(state: state, now: date(18), settings: settings,
                                          history: historyEmpty(at: date(18)), calendar: calendar),
            .suppress)
        // 18:30 — fires
        XCTAssertEqual(
            NotificationDecision.evaluate(state: state, now: date(18, 30), settings: settings,
                                          history: historyEmpty(at: date(18, 30)), calendar: calendar),
            .report(state))
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
