import XCTest
@testable import EightfulCore

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

    // 5-pt workouts (30 min @ 60% max HR) must contribute to the daily total
    // even though they don't earn the 8-pt "green" status.
    func testFivePointWorkoutContributesToPoints() {
        let detail = WorkoutGreenDetail(durationMinutes: 30, avgHR: 115, maxHR: 185, points: 5)
        XCTAssertEqual(DayState(steps: 3_000, workoutDetail: detail).points, 5,
                       "5-pt workout beats 0-pt steps")
        XCTAssertEqual(DayState(steps: 8_000, workoutDetail: detail).points, 5,
                       "5-pt workout ties 3-pt steps via max")
        XCTAssertEqual(DayState(steps: 11_000, workoutDetail: detail).points, 5,
                       "5-pt workout ties 5-pt steps")
        XCTAssertEqual(DayState(steps: 13_000, workoutDetail: detail).points, 8,
                       "8-pt steps beat 5-pt workout")
    }

    func testFivePointWorkoutDoesNotFlipWorkoutGreen() {
        // workoutGreen is the visual "earned the full 8 via a workout" flag.
        // A 5-pt workout earns points but isn't green by itself.
        let detail = WorkoutGreenDetail(durationMinutes: 30, avgHR: 115, maxHR: 185, points: 5)
        let s = DayState(steps: 3_000, workoutDetail: detail)
        XCTAssertFalse(s.workoutGreen)
        XCTAssertFalse(s.isGreen)
        XCTAssertEqual(s.effectiveTier, .red, "no 8-pt workout, low steps -> red tier")
    }

    func testNudgeZonePassesThrough() {
        XCTAssertEqual(DayState(steps: 9_600, workoutGreen: false).nudgeZone, .below10k)
        XCTAssertNil(DayState(steps: 8_000, workoutGreen: false).nudgeZone)
    }
}
