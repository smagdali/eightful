import XCTest
@testable import StepsToEightCore

final class VitalityPointsTests: XCTestCase {
    func testStepPointsBoundaries() {
        XCTAssertEqual(VitalityPoints.fromSteps(0), 0)
        XCTAssertEqual(VitalityPoints.fromSteps(6_999), 0)
        XCTAssertEqual(VitalityPoints.fromSteps(7_000), 3)
        XCTAssertEqual(VitalityPoints.fromSteps(9_999), 3)
        XCTAssertEqual(VitalityPoints.fromSteps(10_000), 5)
        XCTAssertEqual(VitalityPoints.fromSteps(12_499), 5)
        XCTAssertEqual(VitalityPoints.fromSteps(12_500), 8)
    }

    func testWorkout30MinAt70PercentEarns8() {
        // 35yo: max HR 185. 70% = 129.5
        let pts = VitalityPoints.fromWorkout(durationMinutes: 30, avgHR: 130, maxHR: 185)
        XCTAssertEqual(pts, 8)
    }

    func testWorkout60MinAt60PercentEarns8() {
        // 60% of 185 = 111
        let pts = VitalityPoints.fromWorkout(durationMinutes: 60, avgHR: 115, maxHR: 185)
        XCTAssertEqual(pts, 8)
    }

    func testWorkout30MinAt60PercentEarns5() {
        let pts = VitalityPoints.fromWorkout(durationMinutes: 30, avgHR: 115, maxHR: 185)
        XCTAssertEqual(pts, 5)
    }

    func testBelow60PercentEarnsNothing() {
        let pts = VitalityPoints.fromWorkout(durationMinutes: 60, avgHR: 100, maxHR: 185)
        XCTAssertEqual(pts, 0)
    }

    func testUnder30MinutesEarnsNothing() {
        let pts = VitalityPoints.fromWorkout(durationMinutes: 29.9, avgHR: 150, maxHR: 185)
        XCTAssertEqual(pts, 0)
    }

    func test30MinAt70PercentBoundary() {
        // Exactly 70% at exactly 30 min -> 8 pts
        let pts = VitalityPoints.fromWorkout(durationMinutes: 30, avgHR: 129.5, maxHR: 185)
        XCTAssertEqual(pts, 8)
    }

    func testJustBelow70PercentDowngradesTo5() {
        // 69.9% at 30 min -> still >= 60% so 5 pts, not 8
        let pts = VitalityPoints.fromWorkout(durationMinutes: 30, avgHR: 129.0, maxHR: 185)
        XCTAssertEqual(pts, 5)
    }

    func testJustBelow60Minutes() {
        let pts = VitalityPoints.fromWorkout(durationMinutes: 59.9, avgHR: 115, maxHR: 185)
        XCTAssertEqual(pts, 5) // Still qualifies as 30min@60%
    }

    func testInvalidInputs() {
        XCTAssertEqual(VitalityPoints.fromWorkout(durationMinutes: 0, avgHR: 150, maxHR: 185), 0)
        XCTAssertEqual(VitalityPoints.fromWorkout(durationMinutes: 60, avgHR: 0, maxHR: 185), 0)
        XCTAssertEqual(VitalityPoints.fromWorkout(durationMinutes: 60, avgHR: 150, maxHR: 0), 0)
    }
}
