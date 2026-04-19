import XCTest
@testable import EightfulCore

final class StepTierTests: XCTestCase {
    func testBoundaries() {
        XCTAssertEqual(StepTier.from(steps: 0), .red)
        XCTAssertEqual(StepTier.from(steps: 6_999), .red)
        XCTAssertEqual(StepTier.from(steps: 7_000), .orange)
        XCTAssertEqual(StepTier.from(steps: 9_999), .orange)
        XCTAssertEqual(StepTier.from(steps: 10_000), .yellow)
        XCTAssertEqual(StepTier.from(steps: 12_499), .yellow)
        XCTAssertEqual(StepTier.from(steps: 12_500), .green)
        XCTAssertEqual(StepTier.from(steps: 50_000), .green)
    }
}
