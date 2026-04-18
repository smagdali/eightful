import XCTest
@testable import StepsToEightCore

final class MaxHeartRateTests: XCTestCase {
    func testFromAge() {
        XCTAssertEqual(MaxHeartRate.from(age: 30), 190)
        XCTAssertEqual(MaxHeartRate.from(age: 40), 180)
        XCTAssertEqual(MaxHeartRate.from(age: 50), 170)
    }

    func testNegativeAgeClampsToZero() {
        XCTAssertEqual(MaxHeartRate.from(age: 230), 0)
    }

    func testFromDOB() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        let dob = calendar.date(from: DateComponents(year: 1986, month: 4, day: 1))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 18))!
        XCTAssertEqual(MaxHeartRate.from(dateOfBirth: dob, now: now, calendar: calendar), 180) // age 40
    }
}
