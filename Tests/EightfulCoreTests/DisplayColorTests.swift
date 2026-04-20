import XCTest
@testable import EightfulCore

final class DisplayColorTests: XCTestCase {
    private func state(_ steps: Int, workoutGreen: Bool = false) -> DayState {
        DayState(steps: steps, workoutGreen: workoutGreen)
    }

    func testWhiteBelowNudgeZone() {
        XCTAssertEqual(state(0).displayColor, .white)
        XCTAssertEqual(state(6_499).displayColor, .white)
    }

    func testRedInNudgeZones() {
        XCTAssertEqual(state(6_500).displayColor, .red)
        XCTAssertEqual(state(6_999).displayColor, .red)
        XCTAssertEqual(state(9_500).displayColor, .red)
        XCTAssertEqual(state(9_999).displayColor, .red)
        XCTAssertEqual(state(12_000).displayColor, .red)
        XCTAssertEqual(state(12_499).displayColor, .red)
    }

    func testExistingTiers() {
        XCTAssertEqual(state(7_000).displayColor, .orange)
        XCTAssertEqual(state(9_499).displayColor, .orange)
        XCTAssertEqual(state(10_000).displayColor, .yellow)
        XCTAssertEqual(state(11_999).displayColor, .yellow)
        XCTAssertEqual(state(12_500).displayColor, .green)
    }

    func testWorkoutGreenOverrides() {
        XCTAssertEqual(state(3_000, workoutGreen: true).displayColor, .green)
        XCTAssertEqual(state(9_800, workoutGreen: true).displayColor, .green, "workout-green overrides the 'red nudge' display")
    }

    // MARK: - isMaterialChange

    func testMaterialOnTierCross() {
        XCTAssertTrue(state(10_000).isMaterialChange(from: state(9_998)))
    }

    func testMaterialOnNudgeZoneEntry() {
        XCTAssertTrue(state(9_500).isMaterialChange(from: state(9_400)))
    }

    func testMaterialOnNudgeZoneExit() {
        XCTAssertTrue(state(10_000).isMaterialChange(from: state(9_800)))
    }

    func testMaterialOnWorkoutFlip() {
        XCTAssertTrue(state(5_000, workoutGreen: true).isMaterialChange(from: state(5_000, workoutGreen: false)))
    }

    func testNotMaterialWhenInsideSameBand() {
        XCTAssertFalse(state(8_200).isMaterialChange(from: state(8_100)))
        XCTAssertFalse(state(6_600).isMaterialChange(from: state(6_550)))
    }

    func testMaterialWhenOldIsNil() {
        XCTAssertTrue(state(0).isMaterialChange(from: nil))
    }
}
