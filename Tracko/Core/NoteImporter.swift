import Foundation

/// Turns pasted notes into workouts (skill §12, first run). A line that reads as a date
/// ("Mon 13 Oct", "14 October 2025", "Thursday") starts a new workout; the lines under it are its
/// note, kept exactly as typed. Nothing is saved here: the first run shows the result first.
enum NoteImporter {
    /// - Parameter unit: The unit for weights written without one.
    static func workouts(
        from text: String, unit: WeightUnit, now: Date = .now, calendar: Calendar = .current
    ) -> [Workout] {
        var workouts: [Workout] = []
        var date: Date?
        var lines: [String] = []

        func flush() {
            let note = trimBlankLines(lines)
            let workout = Workout(date: date ?? now, text: note, isFinished: true, unit: unit)
            if !WorkoutReader.read(workout, unit: unit).loggedLifts.isEmpty {
                workouts.append(workout)
            }
            lines = []
        }

        for line in text.components(separatedBy: .newlines) {
            if let found = dateHeader(line, now: now, calendar: calendar) {
                flush()
                date = found
            } else {
                lines.append(line)
            }
        }
        flush()
        return workouts.sorted { $0.date < $1.date }
    }

    /// The date a line names, if the line is a date heading rather than sets.
    static func dateHeader(_ line: String, now: Date, calendar: Calendar = .current) -> Date? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        // A date has a day or month name, or a separator ("13/10/2025"); "8 12 11 10" is not one.
        guard !trimmed.isEmpty, trimmed.count <= 40,
              trimmed.contains(where: { $0.isLetter || $0 == "/" || $0 == "." || $0 == "-" })
        else { return nil }
        switch NoteParser.parse(trimmed) {
        case .sets, .nameAndSets: return nil
        default: break
        }
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue),
              let match = detector.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
              var date = match.date
        else { return nil }

        // Without a year, "13 Oct" or "Thursday" means the most recent one, never a future one.
        var guardCount = 0
        while date > now.addingTimeInterval(86_400), guardCount < 3 {
            let step: DateComponents = date.timeIntervalSince(now) <= 8 * 86_400 ? DateComponents(day: -7) : DateComponents(year: -1)
            date = calendar.date(byAdding: step, to: date) ?? date
            guardCount += 1
        }
        return calendar.startOfDay(for: date).addingTimeInterval(12 * 3_600)
    }

    private static func trimBlankLines(_ lines: [String]) -> [String] {
        var result = lines
        while let first = result.first, first.trimmingCharacters(in: .whitespaces).isEmpty { result.removeFirst() }
        while let last = result.last, last.trimmingCharacters(in: .whitespaces).isEmpty { result.removeLast() }
        return result
    }
}
