import XCTest
@testable import EightfulCore

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

    // MARK: - Continuous-window workout scoring

    private let maxHR: Double = 185        // 35yo
    private var thr60: Double { maxHR * 0.6 }   // 111
    private var thr70: Double { maxHR * 0.7 }   // 129.5
    private let t0 = Date(timeIntervalSinceReferenceDate: 0)

    /// Generate evenly-spaced samples at the given bpm spanning [start, start+duration].
    private func samples(durationSeconds: TimeInterval, bpm: Double, start: Date, every: TimeInterval = 5) -> [HeartRateSample] {
        var out: [HeartRateSample] = []
        var t: TimeInterval = 0
        while t <= durationSeconds {
            out.append(HeartRateSample(timestamp: start.addingTimeInterval(t), bpm: bpm))
            t += every
        }
        return out
    }

    func testThirtyContinuousMinutesAt70PercentEarns8() {
        let s = samples(durationSeconds: 30 * 60, bpm: 130, start: t0)   // > 70% of 185
        XCTAssertEqual(VitalityPoints.fromWorkout(samples: s, maxHR: maxHR), 8)
    }

    func testSixtyContinuousMinutesAt60PercentEarns8() {
        let s = samples(durationSeconds: 60 * 60, bpm: 115, start: t0)   // ≥60% but <70%
        XCTAssertEqual(VitalityPoints.fromWorkout(samples: s, maxHR: maxHR), 8)
    }

    func testThirtyContinuousMinutesAt60PercentEarns5() {
        let s = samples(durationSeconds: 30 * 60, bpm: 115, start: t0)
        XCTAssertEqual(VitalityPoints.fromWorkout(samples: s, maxHR: maxHR), 5)
    }

    func testBelow60PercentEarnsNothing() {
        let s = samples(durationSeconds: 60 * 60, bpm: 100, start: t0)
        XCTAssertEqual(VitalityPoints.fromWorkout(samples: s, maxHR: maxHR), 0)
    }

    func testJustUnderThirtyMinutesAt70PercentEarnsNothing() {
        let s = samples(durationSeconds: 30 * 60 - 30, bpm: 130, start: t0)   // 29.5 min
        XCTAssertEqual(VitalityPoints.fromWorkout(samples: s, maxHR: maxHR), 0,
                       "29.5 min above 70% does not also satisfy 30 min above 60% in a single block? It does.")
    }

    func testJustBelow70PercentDowngradesTo5() {
        // 69.7% (avg) ≥60% but <70% → 5pt branch
        let s = samples(durationSeconds: 30 * 60, bpm: 129, start: t0)
        XCTAssertEqual(VitalityPoints.fromWorkout(samples: s, maxHR: maxHR), 5)
    }

    // MARK: - Cases the old workout-average implementation got wrong

    /// "Monday case": 30 continuous minutes at ≥70% bracketed by cool-down.
    /// Workout-wide avg HR is < 70% but the continuous window is ≥ 30 min @ 70%,
    /// so Vitality awards 8.
    func testHardBlockWithCooldownEarns8() {
        let hard = samples(durationSeconds: 30 * 60, bpm: 135, start: t0)
        let coolStart = t0.addingTimeInterval(30 * 60 + 5)
        let cool = samples(durationSeconds: 10 * 60, bpm: 95, start: coolStart)   // <60%
        XCTAssertEqual(VitalityPoints.fromWorkout(samples: hard + cool, maxHR: maxHR), 8)
    }

    /// Stop-start at 60% with no continuous 30-min block earns 0, even though
    /// the workout-wide average meets 60% over 30+ minutes.
    func testStopStartWithoutContinuousBlockEarnsNothing() {
        // 5 min hard @ 75%, 5 min easy @ 50%, repeated 6 times → 60 min total,
        // longest continuous ≥60% block is 5 min.
        var all: [HeartRateSample] = []
        var cursor: TimeInterval = 0
        for _ in 0..<6 {
            all += samples(durationSeconds: 5 * 60, bpm: 140, start: t0.addingTimeInterval(cursor))   // ≥70%
            cursor += 5 * 60 + 5
            all += samples(durationSeconds: 5 * 60, bpm: 90,  start: t0.addingTimeInterval(cursor))   // <60%
            cursor += 5 * 60 + 5
        }
        XCTAssertEqual(VitalityPoints.fromWorkout(samples: all, maxHR: maxHR), 0)
    }

    /// A 5-min HIIT block (≥70%) followed by a long zone-2 block earns 8 via
    /// the 60-min @60% rule — the helper must consider both thresholds.
    func testShortHardBlockPlusLongEasyBlockEarns8() {
        let hard = samples(durationSeconds: 5 * 60, bpm: 140, start: t0)             // ≥70%, <60min
        let easyStart = t0.addingTimeInterval(5 * 60 + 1)
        let easy = samples(durationSeconds: 60 * 60, bpm: 115, start: easyStart)     // ≥60% for 60min
        XCTAssertEqual(VitalityPoints.fromWorkout(samples: hard + easy, maxHR: maxHR), 8)
    }

    // MARK: - Sample-data edge cases

    func testEmptySamplesEarnNothing() {
        XCTAssertEqual(VitalityPoints.fromWorkout(samples: [], maxHR: maxHR), 0)
    }

    func testZeroMaxHREarnsNothing() {
        let s = samples(durationSeconds: 60 * 60, bpm: 150, start: t0)
        XCTAssertEqual(VitalityPoints.fromWorkout(samples: s, maxHR: 0), 0)
    }

    /// A gap larger than `maxGap` (default 60s) between qualifying samples breaks
    /// the run - we can't claim continuity across missing data.
    func testLargeSampleGapBreaksContinuousRun() {
        let first  = samples(durationSeconds: 20 * 60, bpm: 130, start: t0, every: 5)
        let secondStart = t0.addingTimeInterval(20 * 60 + 120)   // 2-min gap
        let second = samples(durationSeconds: 20 * 60, bpm: 130, start: secondStart, every: 5)
        // Each block alone is 20 min; combined elapsed is 42 min; but continuity
        // is broken so the longest qualifying window is 20 min → 0 points.
        XCTAssertEqual(VitalityPoints.fromWorkout(samples: first + second, maxHR: maxHR), 0)
    }

    /// A small gap (≤ maxGap) does not break the run.
    func testSmallSampleGapDoesNotBreakRun() {
        let first  = samples(durationSeconds: 15 * 60, bpm: 130, start: t0, every: 5)
        let secondStart = t0.addingTimeInterval(15 * 60 + 30)   // 30s gap, within tolerance
        let second = samples(durationSeconds: 16 * 60, bpm: 130, start: secondStart, every: 5)
        XCTAssertEqual(VitalityPoints.fromWorkout(samples: first + second, maxHR: maxHR), 8)
    }
}
