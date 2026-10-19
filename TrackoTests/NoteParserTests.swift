import XCTest
@testable import Tracko

/// The note lines skill §12 promises to read.
final class NoteParserTests: XCTestCase {
    private func sets(_ weight: Double, _ reps: [Int], _ unit: WeightUnit? = nil) -> [ParsedSet] {
        reps.map { ParsedSet(weight: weight, unit: unit, reps: $0) }
    }

    func testBlankAndNames() {
        XCTAssertEqual(NoteParser.parse("   "), .blank)
        XCTAssertEqual(NoteParser.parse("Lateral raise"), .name("Lateral raise"))
        XCTAssertEqual(NoteParser.parse("Bench:"), .name("Bench"))
    }

    func testStraightSets() {
        XCTAssertEqual(NoteParser.parse("8 × 12, 11, 10"), .sets(sets(8, [12, 11, 10])))
        XCTAssertEqual(NoteParser.parse("8x12,11,10"), .sets(sets(8, [12, 11, 10])))
        XCTAssertEqual(NoteParser.parse("8 * 12/11/10"), .sets(sets(8, [12, 11, 10])))
        XCTAssertEqual(NoteParser.parse("22.5 kg × 8 8 7"), .sets(sets(22.5, [8, 8, 7], .kg)))
        XCTAssertEqual(NoteParser.parse("100 × 5"), .sets(sets(100, [5])))
    }

    func testSetsTimesReps() {
        XCTAssertEqual(NoteParser.parse("60 kg 3 × 10"), .sets(sets(60, [10, 10, 10], .kg)))
        XCTAssertEqual(NoteParser.parse("3x10 @ 60"), .sets(sets(60, [10, 10, 10])))
        XCTAssertEqual(NoteParser.parse("3 x 10 at 135 lb"), .sets(sets(135, [10, 10, 10], .lb)))
    }

    func testNameAndSetsOnOneLine() {
        XCTAssertEqual(NoteParser.parse("Bench 60 × 8, 8, 7"), .nameAndSets("Bench", sets(60, [8, 8, 7])))
        XCTAssertEqual(
            NoteParser.parse("Lateral raise: 8kg x 12, 11, 10"),
            .nameAndSets("Lateral raise", sets(8, [12, 11, 10], .kg))
        )
    }

    func testWordsAfterTheSetsAreAComment() {
        XCTAssertEqual(NoteParser.parse("60 × 8, 8, 7 felt easy"), .sets(sets(60, [8, 8, 7])))
    }

    func testANameWithANumberStaysAName() {
        XCTAssertEqual(NoteParser.parse("Incline 30° press"), .name("Incline 30° press"))
    }

    func testUnclearLinesSuggestAFix() {
        XCTAssertEqual(NoteParser.parse("8 12 11 10"), .unclear(suggestion: "8 × 12, 11, 10"))
        XCTAssertEqual(NoteParser.parse("Bench 60 8 8 7"), .unclear(suggestion: "Bench 60 × 8, 8, 7"))
        XCTAssertEqual(NoteParser.parse("8 × "), .unclear(suggestion: nil))
        XCTAssertEqual(NoteParser.parse("8 × 0"), .unclear(suggestion: nil))
    }

    func testLiftNamesMatchHoweverTheyreTyped() {
        XCTAssertEqual(LiftName.key("Lateral raises"), LiftName.key("lateral  raise"))
        XCTAssertEqual(LiftName.key("Bench Press"), "bench press")
        XCTAssertEqual(LiftName.key("Bench presses"), "bench press")
    }
}
