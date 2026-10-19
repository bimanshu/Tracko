import XCTest
@testable import Tracko

/// Reading a note into lifts, what's shown under each line, and the store (skill §12).
final class WorkoutTests: XCTestCase {
    private let monday = Date(timeIntervalSince1970: 1_760_000_000)
    private var thursday: Date { monday.addingTimeInterval(3 * 86_400) }
    private var previous: PreviousSession {
        PreviousSession(date: monday, session: LiftSession(weight: 8, reps: [12, 11, 10]))
    }

    // MARK: Reading

    func testReadsLiftsAcrossLines() {
        let workout = Workout(
            date: monday,
            text: ["Push day", "Lateral raise", "8 × 12, 11", "8 × 10", "", "Bench 60 × 8, 8, 7"],
            unit: .kg
        )
        let lifts = workout.loggedLifts(unit: .kg)
        XCTAssertEqual(lifts.map(\.name), ["Lateral raise", "Bench"])
        XCTAssertEqual(lifts[0].sets.map(\.reps), [12, 11, 10])
        XCTAssertEqual(lifts[1].session.volume, 60 * 23)
    }

    func testConvertsFromTheUnitItWasTypedIn() {
        let workout = Workout(date: monday, text: ["Curl", "20 × 10", "Row", "50 kg × 10"], unit: .lb)
        let lifts = workout.loggedLifts(unit: .kg)
        XCTAssertEqual(lifts[0].sets[0].weight, 9.07, accuracy: 0.01)
        XCTAssertEqual(lifts[1].sets[0].weight, 50, accuracy: 0.001)
    }

    func testNotesUnderEachLine() {
        let workout = Workout(
            date: thursday,
            text: ["Lateral raise", "8 × 12, 11", "Face pull", "15 × 15", "8 12"],
            isFinished: false,
            unit: .kg
        )
        let reading = WorkoutReader.read(workout, unit: .kg) { key in key == "lateral raise" ? previous : nil }
        let ids = workout.lines.map(\.id)
        XCTAssertEqual(reading.notes[ids[0]], [.lastTime(previous, next: LiftSession(weight: 8, reps: [12, 11, 11]))])
        XCTAssertEqual(
            reading.notes[ids[1]],
            [.toBeat(done: 184, target: 264, need: LiftMath.LastSetNeed(tie: 10, beat: 11), previousDate: monday)]
        )
        XCTAssertEqual(reading.notes[ids[2]], [.firstTime])
        XCTAssertNil(reading.notes[ids[3]])
        XCTAssertEqual(reading.notes[ids[4]], [.unclear(suggestion: "8 × 12")])
    }

    func testVerdictOnceTheSetsAreIn() {
        let workout = Workout(date: thursday, text: ["Lateral raise", "8 × 12, 11, 11"], isFinished: false, unit: .kg)
        let reading = WorkoutReader.read(workout, unit: .kg) { _ in previous }
        let verdict = LiftMath.verdict(from: previous.session, to: LiftSession(weight: 8, reps: [12, 11, 11]), unit: .kg)
        XCTAssertEqual(reading.notes[workout.lines[1].id], [.verdict(verdict)])
        XCTAssertEqual(verdict.sentence, "+3%. You did 1 extra rep at the same weight.")
    }

    func testSetsWithoutANameAskForOne() {
        let workout = Workout(date: monday, text: ["8 × 10"], unit: .kg)
        XCTAssertEqual(WorkoutReader.read(workout, unit: .kg).notes[workout.lines[0].id], [.needsName])
    }

    // MARK: Store

    private func makeStore(_ workouts: [Workout] = []) -> WorkoutStore {
        WorkoutStore(fileURL: nil, defaults: nil, unit: .kg, workouts: workouts)
    }

    func testEditingTheNote() throws {
        let store = makeStore()
        let workout = store.startWorkout()
        let first = workout.lines[0].id
        store.setText("Lateral raise", line: first, in: workout.id)
        let second = try XCTUnwrap(store.insertLine(after: first, in: workout.id))
        store.setText("8 × 12, 11, 10", line: second, in: workout.id)
        XCTAssertEqual(store.workout(workout.id)?.lines.map(\.text), ["Lateral raise", "8 × 12, 11, 10"])
        XCTAssertEqual(store.removeLine(second, in: workout.id), first)
        XCTAssertEqual(store.workout(workout.id)?.lines.count, 1)
        XCTAssertNil(store.removeLine(first, in: workout.id), "The last line stays")
    }

    func testPastingSplitsLines() {
        let store = makeStore()
        let workout = store.startWorkout()
        let last = store.replaceLine(workout.lines[0].id, in: workout.id, with: ["Bench", "60 × 8, 8, 7"])
        XCTAssertEqual(store.workout(workout.id)?.lines.map(\.text), ["Bench", "60 × 8, 8, 7"])
        XCTAssertEqual(last, store.workout(workout.id)?.lines.last?.id)
    }

    func testClosingAnEmptyWorkoutDiscardsIt() {
        let store = makeStore()
        let workout = store.startWorkout()
        store.close(workout.id)
        XCTAssertNil(store.workout(workout.id))
        XCTAssertNil(store.inProgress)
    }

    func testPreviousIsTheSameLiftsLastSession() {
        let now = Date()
        let earlier = Workout(
            date: now.addingTimeInterval(-3 * 86_400),
            text: ["Lateral raise", "8 × 10, 10, 10", "Bench", "60 × 8"],
            unit: .kg
        )
        let yesterday = Workout(date: now.addingTimeInterval(-86_400), text: ["Squat", "100 × 5"], unit: .kg)
        let store = makeStore([earlier, yesterday])
        let today = store.startWorkout(now: now)
        XCTAssertEqual(store.previous("lateral raise", before: today)?.session, LiftSession(weight: 8, reps: [10, 10, 10]))
        XCTAssertNil(store.previous("deadlift", before: today))
        XCTAssertEqual(store.numbersToBeat().map(\.name), ["Squat"])
        XCTAssertEqual(store.liftHistories().count, 3)
    }

    func testWeeksInARowWaitsForThisWeekToEnd() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        func day(_ month: Int, _ day: Int) throws -> Date {
            try XCTUnwrap(calendar.date(from: DateComponents(year: 2025, month: month, day: day, hour: 12)))
        }
        let store = makeStore([
            Workout(date: try day(10, 14), text: ["Bench", "60 × 8"], unit: .kg),
            Workout(date: try day(10, 8), text: ["Bench", "60 × 8"], unit: .kg),
        ])
        let wednesday = try day(10, 22)
        XCTAssertEqual(store.workoutsThisWeek(now: wednesday, calendar: calendar), 0)
        XCTAssertEqual(store.weeksInARow(now: wednesday, calendar: calendar), 2)
    }

    func testNextWrappedCheckpoint() throws {
        let calendar = Calendar(identifier: .gregorian)
        let first = try XCTUnwrap(calendar.date(from: DateComponents(year: 2025, month: 1, day: 10, hour: 12)))
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2025, month: 3, day: 10, hour: 12)))
        let store = makeStore([Workout(date: first, text: ["Bench", "60 × 8"], unit: .kg)])
        let checkpoint = store.nextCheckpoint(now: now, calendar: calendar)
        XCTAssertEqual(checkpoint?.months, 3)
        XCTAssertEqual(checkpoint?.daysLeft, 31)
    }

    // MARK: Days

    func testRelativeDayNames() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "UTC"))
        let locale = Locale(identifier: "en_GB")
        func day(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
            try XCTUnwrap(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)))
        }
        let now = try day(2025, 10, 20)
        func text(_ date: Date) -> String { DayText.relative(date, now: now, calendar: calendar, locale: locale) }
        XCTAssertEqual(text(now), "Today")
        XCTAssertEqual(text(try day(2025, 10, 19)), "Yesterday")
        XCTAssertEqual(text(try day(2025, 10, 16)), "Thursday")
        XCTAssertEqual(text(try day(2025, 10, 10)), "10 Oct")
        XCTAssertEqual(text(try day(2024, 10, 10)), "10 Oct 2024")
    }
}
