import XCTest
@testable import Tracko

/// Pasted notes become dated workouts, kept as typed (skill §12, first run).
final class NoteImporterTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func now() throws -> Date {
        try XCTUnwrap(calendar.date(from: DateComponents(year: 2025, month: 10, day: 20, hour: 12)))
    }

    func testSplitsNotesAtDates() throws {
        let text = """
        Mon 13 Oct 2025
        Lateral raise
        8 × 10, 10, 10

        Thu 16 Oct 2025
        Lateral raise 8 × 12, 11, 10
        Felt strong
        """
        let workouts = NoteImporter.workouts(from: text, unit: .kg, now: try now(), calendar: calendar)
        XCTAssertEqual(workouts.count, 2)
        XCTAssertEqual(workouts.map { calendar.component(.day, from: $0.date) }, [13, 16])
        XCTAssertEqual(workouts[0].lines.map(\.text), ["Lateral raise", "8 × 10, 10, 10"])
        XCTAssertEqual(workouts[1].lines.map(\.text), ["Lateral raise 8 × 12, 11, 10", "Felt strong"])
        XCTAssertTrue(workouts.allSatisfy(\.isFinished))
    }

    func testNotesWithoutDatesBecomeOneWorkout() throws {
        let workouts = NoteImporter.workouts(from: "Bench 60 × 8, 8, 7\nSquat 100 × 5", unit: .kg, now: try now())
        XCTAssertEqual(workouts.count, 1)
        XCTAssertEqual(workouts[0].loggedLifts(unit: .kg).map(\.name), ["Bench", "Squat"])
    }

    func testTextWithoutSetsImportsNothing() {
        XCTAssertTrue(NoteImporter.workouts(from: "Shopping list\nmilk", unit: .kg).isEmpty)
    }
}
