import XCTest
@testable import Tracko

/// The onboarding's numbers are real maths, and the same in kg and lb (skill §7.5).
final class DemoContentTests: XCTestCase {
    private let units: [WeightUnit] = [.kg, .lb]

    func testThursdayVerdict() {
        for unit in units {
            let verdict = DemoContent(unit: unit).thursdayVerdict
            XCTAssertEqual(verdict.percent, 10)
            XCTAssertEqual(verdict.reason, "You did 3 extra reps at the same weight.")
        }
    }

    func testTodayBeatsThursdayByOneRep() {
        for unit in units {
            let demo = DemoContent(unit: unit)
            XCTAssertEqual(demo.lastSetNeed, LiftMath.LastSetNeed(tie: 10, beat: 11))
            XCTAssertEqual(demo.todayVerdict.percent, 3)
            XCTAssertGreaterThan(demo.today.volume, demo.thursday.volume)
        }
    }

    func testTwelveWeeksOfGrowth() {
        for unit in units {
            XCTAssertEqual(DemoContent(unit: unit).growthPercent, 25)
        }
    }

    func testGrowthCurveIsHonest() {
        let curve = DemoContent().growthCurve
        XCTAssertEqual(curve.count, 13)
        XCTAssertEqual(curve.first ?? -1, 0, accuracy: 1e-9)
        XCTAssertEqual(curve.last ?? -1, 1, accuracy: 1e-9)
        XCTAssertEqual(curve, curve.sorted(), "never goes down")
        // Fast early, slower later.
        XCTAssertGreaterThan(curve[6] - curve[0], curve[12] - curve[6])
    }

    func testNoteLines() {
        XCTAssertEqual(DemoContent(unit: .kg).noteLine(DemoContent(unit: .kg).thursday), "8 × 12, 11, 10")
        XCTAssertEqual(DemoContent(unit: .lb).noteLine(DemoContent(unit: .lb).thursday), "20 × 12, 11, 10")
    }
}
