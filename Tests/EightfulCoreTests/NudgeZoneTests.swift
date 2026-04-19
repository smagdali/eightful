import XCTest
@testable import EightfulCore

final class NudgeZoneTests: XCTestCase {
    func testZoneBoundaries() {
        XCTAssertNil(NudgeZone.current(steps: 6_499))
        XCTAssertEqual(NudgeZone.current(steps: 6_500), .below7k)
        XCTAssertEqual(NudgeZone.current(steps: 6_999), .below7k)
        XCTAssertNil(NudgeZone.current(steps: 7_000))

        XCTAssertNil(NudgeZone.current(steps: 9_499))
        XCTAssertEqual(NudgeZone.current(steps: 9_500), .below10k)
        XCTAssertEqual(NudgeZone.current(steps: 9_999), .below10k)
        XCTAssertNil(NudgeZone.current(steps: 10_000))

        XCTAssertNil(NudgeZone.current(steps: 11_999))
        XCTAssertEqual(NudgeZone.current(steps: 12_000), .below12500)
        XCTAssertEqual(NudgeZone.current(steps: 12_499), .below12500)
        XCTAssertNil(NudgeZone.current(steps: 12_500))
    }

    func testThresholds() {
        XCTAssertEqual(NudgeZone.below7k.threshold, 7_000)
        XCTAssertEqual(NudgeZone.below10k.threshold, 10_000)
        XCTAssertEqual(NudgeZone.below12500.threshold, 12_500)
    }
}
