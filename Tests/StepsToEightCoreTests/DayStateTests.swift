import XCTest
@testable import StepsToEightCore

final class DayStateTests: XCTestCase {
    func testTierMirrorsSteps() {
        XCTAssertEqual(DayState(steps: 5_000, workoutGreen: false).tier, .red)
        XCTAssertEqual(DayState(steps: 8_000, workoutGreen: false).tier, .orange)
        XCTAssertEqual(DayState(steps: 11_000, workoutGreen: false).tier, .yellow)
        XCTAssertEqual(DayState(steps: 13_000, workoutGreen: false).tier, .green)
    }

    func testWorkoutGreenOverridesEffectiveTier() {
        let s = DayState(steps: 3_000, workoutGreen: true)
        XCTAssertEqual(s.tier, .red, "raw tier reflects steps only")
        XCTAssertEqual(s.effectiveTier, .green, "effective tier flips with workout")
        XCTAssertTrue(s.isGreen)
    }

    func testStepsGreenIsGreenRegardlessOfWorkout() {
        let s = DayState(steps: 15_000, workoutGreen: false)
        XCTAssertTrue(s.isGreen)
    }

    func testPointsAreMaxOfStepAndWorkout() {
        XCTAssertEqual(DayState(steps: 3_000, workoutGreen: true).points, 8)
        XCTAssertEqual(DayState(steps: 11_000, workoutGreen: true).points, 8, "workout-8 overrides 5 from steps")
        XCTAssertEqual(DayState(steps: 11_000, workoutGreen: false).points, 5)
        XCTAssertEqual(DayState(steps: 3_000, workoutGreen: false).points, 0)
    }

    func testNudgeZonePassesThrough() {
        XCTAssertEqual(DayState(steps: 9_600, workoutGreen: false).nudgeZone, .below10k)
        XCTAssertNil(DayState(steps: 8_000, workoutGreen: false).nudgeZone)
    }
}
