import Foundation
import Observation
import os

/// Every workout, saved on the device after each change, so a set is never lost (rule 2). Views
/// reach it through the environment: `@Environment(WorkoutStore.self)`.
@Observable
final class WorkoutStore {
    /// Newest first.
    private(set) var workouts: [Workout] = []
    /// The unit everything is shown in (§7.5).
    private(set) var unit: WeightUnit

    private let fileURL: URL?
    private let defaults: UserDefaults?
    private static let log = Logger(subsystem: "com.bimanshu.tracko", category: "WorkoutStore")

    /// - Parameters:
    ///   - fileURL: Where workouts are saved; nil keeps them in memory (previews, tests, demos).
    ///   - defaults: Where the unit setting is kept; nil uses `unit` and doesn't save it.
    init(
        fileURL: URL? = WorkoutStore.defaultFileURL,
        defaults: UserDefaults? = .standard,
        unit: WeightUnit = .preferred,
        workouts: [Workout] = []
    ) {
        self.fileURL = fileURL
        self.defaults = defaults
        self.unit = defaults?.string(forKey: StorageKey.unit).flatMap(WeightUnit.init(rawValue:)) ?? unit
        self.workouts = workouts.sorted { $0.date > $1.date }
        load()
    }

    static var defaultFileURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("workouts.json")
    }

    // MARK: Reading

    /// The workout being logged, if one is open.
    var inProgress: Workout? { workouts.first { !$0.isFinished } }

    func workout(_ id: Workout.ID) -> Workout? { workouts.first { $0.id == id } }

    /// Finished workouts that logged at least one set, newest first.
    var loggedWorkouts: [Workout] {
        workouts.filter { $0.isFinished && !$0.loggedLifts(unit: unit).isEmpty }
    }

    /// A lift's most recent session before `workout` (§7.2: the same exercise, not the last workout).
    func previous(_ key: String, before workout: Workout) -> PreviousSession? {
        for other in workouts where other.id != workout.id && other.date < workout.date {
            if let lift = other.loggedLifts(unit: unit).first(where: { $0.key == key }) {
                return PreviousSession(date: other.date, session: lift.session)
            }
        }
        return nil
    }

    /// The note, read, with every lift compared to its previous session.
    func reading(of workout: Workout) -> WorkoutReading {
        WorkoutReader.read(workout, unit: unit) { key in
            self.previous(key, before: workout)
        }
    }

    /// Today's numbers to beat: each lift from the last workout, with its next target.
    func numbersToBeat() -> [TargetRow] {
        guard let last = loggedWorkouts.first else { return [] }
        return last.loggedLifts(unit: unit).map { lift in
            TargetRow(
                name: lift.name,
                key: lift.key,
                last: PreviousSession(date: last.date, session: lift.session),
                next: LiftMath.nextTarget(after: lift.session)
            )
        }
    }

    /// Every lift ever logged, most recently trained first.
    func liftHistories() -> [LiftHistory] {
        var byKey: [String: LiftHistory] = [:]
        for workout in loggedWorkouts.reversed() {
            for lift in workout.loggedLifts(unit: unit) {
                let session = PreviousSession(date: workout.date, session: lift.session)
                if var history = byKey[lift.key] {
                    history.name = lift.name
                    history.sessions.append(session)
                    byKey[lift.key] = history
                } else {
                    byKey[lift.key] = LiftHistory(key: lift.key, name: lift.name, sessions: [session])
                }
            }
        }
        return byKey.values.sorted {
            $0.latest.date != $1.latest.date ? $0.latest.date > $1.latest.date : $0.name < $1.name
        }
    }

    func history(of key: String) -> LiftHistory? {
        liftHistories().first { $0.key == key }
    }

    // MARK: Weeks and checkpoints (§6.4, §6.5)

    func workoutsThisWeek(now: Date = .now, calendar: Calendar = .current) -> Int {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return loggedWorkouts.filter { week.contains($0.date) }.count
    }

    /// Weeks trained in a row, ending this week (or last week, while this one isn't over). Rest
    /// days never break it (§6.5).
    func weeksInARow(now: Date = .now, calendar: Calendar = .current) -> Int {
        let weeks = Set(loggedWorkouts.compactMap { calendar.dateInterval(of: .weekOfYear, for: $0.date)?.start })
        guard var week = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }
        if !weeks.contains(week), let last = calendar.date(byAdding: .weekOfYear, value: -1, to: week) {
            week = last
        }
        var count = 0
        while weeks.contains(week), let earlier = calendar.date(byAdding: .weekOfYear, value: -1, to: week) {
            count += 1
            week = earlier
        }
        return count
    }

    var firstWorkoutDate: Date? { loggedWorkouts.last?.date }

    /// The next Wrapped: 3, 6, 9, 12… months from the first workout (§6.4).
    func nextCheckpoint(now: Date = .now, calendar: Calendar = .current) -> Checkpoint? {
        guard let first = firstWorkoutDate else { return nil }
        var start = first
        for months in stride(from: 3, through: 600, by: 3) {
            guard let date = calendar.date(byAdding: .month, value: months, to: first) else { return nil }
            if date > now {
                let progress = now.timeIntervalSince(start) / date.timeIntervalSince(start)
                let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: date)).day ?? 0
                return Checkpoint(months: months, date: date, daysLeft: days, progress: min(max(progress, 0), 1))
            }
            start = date
        }
        return nil
    }

    // MARK: Writing (each change is saved at once)

    /// Opens a workout for logging, or returns the one already open.
    @discardableResult
    func startWorkout(now: Date = .now) -> Workout {
        if let inProgress { return inProgress }
        let workout = Workout(date: now, lines: [NoteText(text: "")], unit: unit)
        workouts.insert(workout, at: 0)
        save()
        return workout
    }

    func setText(_ text: String, line: NoteText.ID, in workout: Workout.ID) {
        update(workout) { workout in
            guard let index = workout.lines.firstIndex(where: { $0.id == line }),
                  workout.lines[index].text != text
            else { return }
            workout.lines[index].text = text
        }
    }

    /// Adds an empty line after `line` and returns it.
    @discardableResult
    func insertLine(after line: NoteText.ID, in workout: Workout.ID, text: String = "") -> NoteText.ID? {
        var added: NoteText.ID?
        update(workout) { workout in
            let new = NoteText(text: text)
            let index = workout.lines.firstIndex { $0.id == line }.map { $0 + 1 } ?? workout.lines.count
            workout.lines.insert(new, at: index)
            added = new.id
        }
        return added
    }

    /// Removes a line, keeping at least one, and returns the line before it.
    @discardableResult
    func removeLine(_ line: NoteText.ID, in workout: Workout.ID) -> NoteText.ID? {
        var before: NoteText.ID?
        update(workout) { workout in
            guard workout.lines.count > 1, let index = workout.lines.firstIndex(where: { $0.id == line }) else { return }
            workout.lines.remove(at: index)
            before = workout.lines[max(index - 1, 0)].id
        }
        return before
    }

    /// Replaces a line with several (a paste of many lines) and returns the last of them.
    @discardableResult
    func replaceLine(_ line: NoteText.ID, in workout: Workout.ID, with texts: [String]) -> NoteText.ID? {
        guard let first = texts.first else { return nil }
        var last: NoteText.ID?
        update(workout) { workout in
            guard let index = workout.lines.firstIndex(where: { $0.id == line }) else { return }
            workout.lines[index].text = first
            let rest = texts.dropFirst().map { NoteText(text: $0) }
            workout.lines.insert(contentsOf: rest, at: index + 1)
            last = rest.last?.id ?? workout.lines[index].id
        }
        return last
    }

    func finish(_ id: Workout.ID) {
        update(id) { $0.isFinished = true }
    }

    /// Leaves the log. A workout with nothing typed is thrown away; anything else stays open.
    func close(_ id: Workout.ID) {
        guard let workout = self.workout(id), workout.isEmpty else { return }
        delete(id)
    }

    func delete(_ id: Workout.ID) {
        workouts.removeAll { $0.id == id }
        save()
    }

    /// Adds imported workouts (already shown to the user, §12).
    func add(_ imported: [Workout]) {
        workouts = (workouts + imported).sorted { $0.date > $1.date }
        save()
    }

    func setUnit(_ unit: WeightUnit) {
        self.unit = unit
        defaults?.set(unit.rawValue, forKey: StorageKey.unit)
    }

    // MARK: Saving

    private func update(_ id: Workout.ID, _ change: (inout Workout) -> Void) {
        guard let index = workouts.firstIndex(where: { $0.id == id }) else { return }
        var workout = workouts[index]
        change(&workout)
        guard workout != workouts[index] else { return }
        workouts[index] = workout
        save()
    }

    private func load() {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return }
        do {
            let saved = try JSONDecoder.tracko.decode([Workout].self, from: data)
            workouts = (workouts + saved).sorted { $0.date > $1.date }
        } catch {
            Self.log.error("Couldn't read saved workouts: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func save() {
        guard let fileURL else { return }
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try JSONEncoder.tracko.encode(workouts).write(to: fileURL, options: .atomic)
        } catch {
            Self.log.error("Couldn't save workouts: \(error.localizedDescription, privacy: .public)")
        }
    }
}

/// A lift to beat today: last time's session and the next target.
struct TargetRow: Identifiable, Equatable {
    let name: String
    let key: String
    let last: PreviousSession
    let next: LiftSession

    var id: String { key }
}

/// Every session of one lift, oldest first.
struct LiftHistory: Identifiable, Equatable {
    let key: String
    /// As it was typed most recently.
    var name: String
    var sessions: [PreviousSession]

    var id: String { key }
    var first: PreviousSession { sessions[0] }
    var latest: PreviousSession { sessions[sessions.count - 1] }

    /// The change in estimated max from the first session to the latest (§7.1).
    var percent: Int {
        LiftMath.displayPercent(from: first.session.estimatedOneRepMax, to: latest.session.estimatedOneRepMax)
    }
}

/// The next Wrapped checkpoint and how far along the way to it the user is.
struct Checkpoint: Equatable {
    let months: Int
    let date: Date
    let daysLeft: Int
    let progress: Double
}

extension JSONEncoder {
    static var tracko: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var tracko: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
