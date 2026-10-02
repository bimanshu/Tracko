import XCTest
@testable import Tracko

/// Keeps the reference examples in skill §7 true.
final class LiftMathTests: XCTestCase {
    private let monday = LiftSession(weight: 8, reps: [10, 10, 10])
    private let thursday = LiftSession(weight: 8, reps: [12, 11, 10])
    private let usEnglish = Locale(identifier: "en_US")

    // MARK: §7.1 reference example

    func testVolume() {
        XCTAssertEqual(monday.volume, 240)
        XCTAssertEqual(thursday.volume, 264)
    }

    func testVolumeChangeIsPlusTenPercent() {
        XCTAssertEqual(LiftMath.displayPercent(from: monday.volume, to: thursday.volume), 10)
    }

    func testEstimatedOneRepMax() {
        XCTAssertEqual(monday.estimatedOneRepMax, 10.667, accuracy: 0.001)
        XCTAssertEqual(thursday.estimatedOneRepMax, 11.2, accuracy: 0.0001)
        XCTAssertEqual(LiftMath.formatNumber(monday.estimatedOneRepMax, locale: usEnglish), "10.7")
        XCTAssertEqual(LiftMath.displayPercent(from: monday.estimatedOneRepMax, to: thursday.estimatedOneRepMax), 5)
    }

    func testThreeExtraReps() {
        XCTAssertEqual(thursday.totalReps - monday.totalReps, 3)
    }

    // MARK: Verdict (§6.1, §7.2, §7.3)

    func testVerdictSentence() {
        let verdict = LiftMath.verdict(from: monday, to: thursday, unit: .kg)
        XCTAssertEqual(verdict.sentence, "+10%. You did 3 extra reps at the same weight.")
        XCTAssertEqual(verdict.trend, .up)
    }

    func testOneExtraRepIsSingular() {
        let today = LiftSession(weight: 8, reps: [12, 11, 11])
        let verdict = LiftMath.verdict(from: thursday, to: today, unit: .kg)
        XCTAssertEqual(verdict.sentence, "+3%. You did 1 extra rep at the same weight.")
    }

    func testDipReadsAsRecovery() {
        let lighter = LiftSession(weight: 8, reps: [10, 9, 8])
        let verdict = LiftMath.verdict(from: monday, to: lighter, unit: .kg)
        XCTAssertEqual(verdict.percent, -10)
        XCTAssertEqual(verdict.trend, .down)
        XCTAssertEqual(verdict.sentence, "\u{2212}10%. Lighter day, that's recovery.")
    }

    func testDifferentWeightLeadsWithStrength() {
        let heavier = LiftSession(weight: 9, reps: [10, 10, 10])
        let verdict = LiftMath.verdict(from: thursday, to: heavier, unit: .kg)
        // e1RM 9 × (1 + 10/30) = 12 vs 11.2 → +7%.
        XCTAssertEqual(verdict.percent, 7)
        XCTAssertEqual(verdict.reason, "You moved up to 9 kg.")
    }

    // MARK: Number to beat (§6.2)

    func testLastSetTiesAtTenBeatsAtEleven() {
        let done = LiftSession(weight: 8, reps: [12, 11]).sets
        let need = LiftMath.lastSetNeed(target: thursday.volume, done: done, weight: 8)
        XCTAssertEqual(need, LiftMath.LastSetNeed(tie: 10, beat: 11))
    }

    func testLastSetWithoutExactTie() {
        // 264 − 8 × 23 = 80 left; at 9 kg that's 8.9 reps, so 9 beats and nothing ties.
        let done = LiftSession(weight: 8, reps: [12, 11]).sets
        let need = LiftMath.lastSetNeed(target: 264, done: done, weight: 9)
        XCTAssertEqual(need, LiftMath.LastSetNeed(tie: nil, beat: 9))
    }

    func testGoUpOption() {
        let option = LiftMath.goUpOption(target: thursday.volume, weight: 8, step: 1, sets: 3)
        XCTAssertEqual(option, LiftSession(weight: 9, reps: [10, 10, 10]))
    }

    func testGoUpOptionMustBeatNotTie() {
        // 270 ÷ (9 × 3) = 10 exactly, so 10 reps would only tie.
        let option = LiftMath.goUpOption(target: 270, weight: 8, step: 1, sets: 3)
        XCTAssertEqual(option, LiftSession(weight: 9, reps: [11, 11, 11]))
    }

    // MARK: Units (§7.5)

    func testPoundsTellTheSameStory() {
        let mondayLb = LiftSession(weight: 20, reps: [10, 10, 10])
        let thursdayLb = LiftSession(weight: 20, reps: [12, 11, 10])
        XCTAssertEqual(LiftMath.displayPercent(from: mondayLb.volume, to: thursdayLb.volume), 10)
        XCTAssertEqual(
            LiftMath.displayPercent(from: mondayLb.estimatedOneRepMax, to: thursdayLb.estimatedOneRepMax), 5
        )
        XCTAssertEqual(
            LiftMath.goUpOption(target: thursdayLb.volume, weight: 20, step: 5, sets: 3),
            LiftSession(weight: 25, reps: [9, 9, 9])
        )
    }

    func testUnitConversion() {
        XCTAssertEqual(LiftMath.convert(100, from: .kg, to: .lb), 220.462, accuracy: 0.001)
        XCTAssertEqual(LiftMath.convert(220.462262, from: .lb, to: .kg), 100, accuracy: 0.001)
        XCTAssertEqual(LiftMath.convert(8, from: .kg, to: .kg), 8)
    }

    func testFormatting() {
        XCTAssertEqual(LiftMath.formatPercent(10), "+10%")
        XCTAssertEqual(LiftMath.formatPercent(0), "0%")
        XCTAssertEqual(LiftMath.formatPercent(-3), "\u{2212}3%")
        XCTAssertEqual(LiftMath.format(weight: 8, unit: .kg, locale: usEnglish), "8 kg")
        XCTAssertEqual(LiftMath.format(weight: 22.5, unit: .lb, locale: usEnglish), "22.5 lb")
    }

    // MARK: Cut mode (§7.4)

    func testRelativeStrength() {
        let before = LiftMath.relativeStrength(oneRepMax: 76, bodyweight: 90)
        let after = LiftMath.relativeStrength(oneRepMax: 76, bodyweight: 86)
        XCTAssertEqual(before, 0.84, accuracy: 0.005)
        XCTAssertEqual(after, 0.88, accuracy: 0.005)
        XCTAssertEqual(LiftMath.displayPercent(from: before, to: after), 5)
    }

    func testTrendWeightUsesLastSevenWeighIns() throws {
        let trend = try XCTUnwrap(LiftMath.trendWeight([100, 90, 88, 87, 86, 85, 84, 83]))
        XCTAssertEqual(trend, 603.0 / 7, accuracy: 0.0001)
        XCTAssertNil(LiftMath.trendWeight([]))
    }

    // MARK: Honest growth (§6.3)

    func testGrowthSlowsDown() {
        let early = LiftMath.honestGrowth(week: 4) - LiftMath.honestGrowth(week: 0)
        let late = LiftMath.honestGrowth(week: 12) - LiftMath.honestGrowth(week: 8)
        XCTAssertGreaterThan(early, late)
        XCTAssertEqual(LiftMath.honestProgress(week: 12, of: 12), 1)
        XCTAssertEqual(LiftMath.honestProgress(week: 0, of: 12), 0)
    }
}
