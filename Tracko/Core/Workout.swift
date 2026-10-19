import Foundation

/// One line of a workout note, exactly as typed. The text is the record; everything Tracko shows
/// is read from it, so nothing typed is ever lost to a parse (rule 2).
struct NoteText: Codable, Identifiable, Hashable, Sendable {
    var id = UUID()
    var text: String
}

/// A workout: one note, on one day.
struct Workout: Codable, Identifiable, Hashable, Sendable {
    var id = UUID()
    var date: Date
    var lines: [NoteText]
    var isFinished = false
    /// The unit the note was typed in: weights written without one ("8 × 12") are in this unit,
    /// so changing the setting later never changes what was lifted.
    var unit: WeightUnit?

    init(id: UUID = UUID(), date: Date, lines: [NoteText], isFinished: Bool = false, unit: WeightUnit?) {
        self.id = id
        self.date = date
        self.lines = lines
        self.isFinished = isFinished
        self.unit = unit
    }

    init(date: Date, text: [String], isFinished: Bool = true, unit: WeightUnit?) {
        self.init(date: date, lines: text.map { NoteText(text: $0) }, isFinished: isFinished, unit: unit)
    }

    /// True when nothing but blank lines was typed.
    var isEmpty: Bool {
        lines.allSatisfy { $0.text.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    /// The lifts with sets, in note order, read in `unit`. A lift typed twice is merged into one.
    func loggedLifts(unit: WeightUnit) -> [LoggedLift] {
        var result: [LoggedLift] = []
        for lift in WorkoutReader.read(self, unit: unit).lifts where !lift.sets.isEmpty {
            if let index = result.firstIndex(where: { $0.key == lift.key }) {
                result[index].sets += lift.sets
            } else {
                result.append(lift)
            }
        }
        return result
    }
}

/// A lift as it appears in one note: its name, and the sets typed under (or beside) it.
struct LoggedLift: Identifiable, Equatable, Sendable {
    /// The line its name is on.
    let id: UUID
    var name: String
    var sets: [LiftSet]
    /// The last line holding one of its sets.
    var lastSetLine: UUID?

    var key: String { LiftName.key(name) }
    var session: LiftSession { LiftSession(sets: sets) }
}

/// A lift's most recent earlier session: what today is compared with (§7.2).
struct PreviousSession: Equatable, Sendable {
    let date: Date
    let session: LiftSession
}

/// What Tracko shows under a line of the note (skill §12).
enum LineNote: Equatable, Sendable {
    /// Under a lift's name: last time's sets and the next target.
    case lastTime(PreviousSession, next: LiftSession)
    /// Under a lift's name, the first time it's logged.
    case firstTime
    /// Under its sets, until they're all in: the total so far against last time's, and what the
    /// last set needs when one set is left.
    case toBeat(done: Double, target: Double, need: LiftMath.LastSetNeed?, previousDate: Date)
    /// Under its sets, once there are as many as last time.
    case verdict(Verdict)
    /// A line with numbers Tracko couldn't read.
    case unclear(suggestion: String?)
    /// Sets with no lift name above them.
    case needsName
}

/// A note, read: its lifts and the notes to show under each line.
struct WorkoutReading: Equatable, Sendable {
    var lifts: [LoggedLift] = []
    var roles: [UUID: NoteLine] = [:]
    var notes: [UUID: [LineNote]] = [:]

    /// Lifts that have sets.
    var loggedLifts: [LoggedLift] { lifts.filter { !$0.sets.isEmpty } }
}

enum WorkoutReader {
    /// Groups the note into lifts, with every weight converted to `unit`.
    static func read(_ workout: Workout, unit: WeightUnit) -> WorkoutReading {
        let typedUnit = workout.unit ?? unit
        var reading = WorkoutReading()
        var current: Int?
        for line in workout.lines {
            let role = NoteParser.parse(line.text)
            reading.roles[line.id] = role
            switch role {
            case .blank:
                break
            case .name(let name):
                reading.lifts.append(LoggedLift(id: line.id, name: name, sets: [], lastSetLine: nil))
                current = reading.lifts.count - 1
            case .nameAndSets(let name, let sets):
                reading.lifts.append(
                    LoggedLift(id: line.id, name: name, sets: convert(sets, from: typedUnit, to: unit), lastSetLine: line.id)
                )
                current = reading.lifts.count - 1
            case .sets(let sets):
                if let current {
                    reading.lifts[current].sets += convert(sets, from: typedUnit, to: unit)
                    reading.lifts[current].lastSetLine = line.id
                } else {
                    reading.notes[line.id, default: []].append(.needsName)
                }
            case .unclear(let suggestion):
                reading.notes[line.id, default: []].append(.unclear(suggestion: suggestion))
            }
        }
        return reading
    }

    /// Reads the note and adds what to show under each line, comparing every lift with its
    /// previous session (`previous` looks it up by `LiftName.key`).
    static func read(
        _ workout: Workout,
        unit: WeightUnit,
        previous: (String) -> PreviousSession?
    ) -> WorkoutReading {
        var reading = read(workout, unit: unit)
        for lift in reading.lifts {
            let before = previous(lift.key)
            if let before {
                reading.notes[lift.id, default: []].insert(
                    .lastTime(before, next: LiftMath.nextTarget(after: before.session)), at: 0
                )
            } else if !lift.sets.isEmpty {
                reading.notes[lift.id, default: []].insert(.firstTime, at: 0)
            }
            guard let before, let setLine = lift.lastSetLine else { continue }
            let session = lift.session
            if session.sets.count >= before.session.sets.count || workout.isFinished {
                let verdict = LiftMath.verdict(from: before.session, to: session, unit: unit)
                reading.notes[setLine, default: []].append(.verdict(verdict))
            } else {
                var need: LiftMath.LastSetNeed?
                if session.sets.count == before.session.sets.count - 1, let weight = session.singleWeight {
                    need = LiftMath.lastSetNeed(target: before.session.volume, done: session.sets, weight: weight)
                }
                reading.notes[setLine, default: []].append(
                    .toBeat(done: session.volume, target: before.session.volume, need: need, previousDate: before.date)
                )
            }
        }
        return reading
    }

    private static func convert(_ sets: [ParsedSet], from typedUnit: WeightUnit, to unit: WeightUnit) -> [LiftSet] {
        sets.map { set in
            let weight = LiftMath.convert(set.weight, from: set.unit ?? typedUnit, to: unit)
            return LiftSet(weight: (weight * 100).rounded() / 100, reps: set.reps)
        }
    }
}
