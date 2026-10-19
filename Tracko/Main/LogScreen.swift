import SwiftUI

/// Opens on the log; Finish turns it into the growth report, and Done closes both.
struct LogFlow: View {
    let workoutID: Workout.ID
    @State private var isShowingReport = LaunchScreen.current == .report
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            if isShowingReport {
                ReportScreen(workoutID: workoutID) { dismiss() }
                    .transition(.opacity)
            } else {
                LogScreen(workoutID: workoutID) {
                    withAnimation(Motion.fade) { isShowingReport = true }
                } onClose: {
                    dismiss()
                }
                .transition(.opacity)
            }
        }
        .background(Theme.bgPage)
    }
}

/// The log (skill §12): a workout is one note. Each line is read as it's typed, and Tracko
/// writes what it means under it: last time and the next target under a lift's name, what the
/// last set needs under its sets, then the verdict.
struct LogScreen: View {
    let workoutID: Workout.ID
    var onFinish: () -> Void
    var onClose: () -> Void

    @Environment(WorkoutStore.self) private var store
    @State private var focusedLine: NoteText.ID?

    var body: some View {
        let workout = store.workout(workoutID)
        let reading = workout.map { store.reading(of: $0) } ?? WorkoutReading()
        VStack(spacing: 0) {
            topBar(canFinish: !reading.loggedLifts.isEmpty)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let workout {
                        Text(DayText.relative(workout.date))
                            .typeRole(.screenTitle)
                            .foregroundStyle(Theme.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                            .padding(.bottom, Space.xs)
                        ForEach(Array(workout.lines.enumerated()), id: \.element.id) { index, line in
                            LogLineRow(
                                text: Binding(
                                    get: { line.text },
                                    set: { store.setText($0, line: line.id, in: workoutID) }
                                ),
                                line: line,
                                role: reading.roles[line.id] ?? .blank,
                                notes: reading.notes[line.id] ?? [],
                                placeholder: placeholder(at: index, in: workout, reading: reading),
                                startsLift: index > 0 && reading.roles[line.id]?.startsLift == true,
                                unit: store.unit,
                                focusedLine: $focusedLine,
                                onReturn: { focusedLine = store.insertLine(after: line.id, in: workoutID) },
                                onDeleteEmpty: {
                                    if let before = store.removeLine(line.id, in: workoutID) { focusedLine = before }
                                },
                                onPasteLines: { lines in
                                    focusedLine = store.replaceLine(line.id, in: workoutID, with: lines)
                                },
                                onUseSuggestion: { suggestion in
                                    store.setText(suggestion, line: line.id, in: workoutID)
                                }
                            )
                        }
                        if workout.lines.count == 1, workout.isEmpty {
                            Text("Type a lift’s name, then its sets on the next line, the way you would in Notes.")
                                .typeRole(.caption)
                                .foregroundStyle(Theme.textTertiary)
                                .padding(.top, Space.s)
                        }
                    }
                }
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.s)
                .padding(.bottom, Space.xxl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Theme.bgPage)
        .onAppear {
            if let workout, workout.isEmpty { focusedLine = workout.lines.first?.id }
        }
    }

    /// Close and Finish only, so they fit side by side at every text size.
    private func topBar(canFinish: Bool) -> some View {
        HStack {
            Button("Close") {
                focusedLine = nil
                store.close(workoutID)
                onClose()
            }
            .typeRole(.body)
            .foregroundStyle(Theme.textSecondary)
            .frame(minWidth: 44, minHeight: 44, alignment: .leading)
            Spacer()
            Button("Finish") {
                focusedLine = nil
                store.finish(workoutID)
                onFinish()
            }
            .buttonStyle(CompactButtonStyle())
            .disabled(!canFinish)
        }
        .padding(.horizontal, Space.gutter)
        .padding(.vertical, Space.s)
    }

    /// A hint on the line being typed: a lift's name first, then its sets.
    private func placeholder(at index: Int, in workout: Workout, reading: WorkoutReading) -> String {
        let isLast = index == workout.lines.count - 1
        guard workout.lines[index].id == focusedLine || isLast else { return "" }
        guard index > 0 else { return "Lateral raise" }
        switch reading.roles[workout.lines[index - 1].id] {
        case .name?: return "8 × 12, 11, 10"
        case .sets?, .nameAndSets?: return "Next lift"
        default: return ""
        }
    }
}

private extension NoteLine {
    var startsLift: Bool {
        switch self {
        case .name, .nameAndSets: return true
        default: return false
        }
    }

    var isName: Bool { startsLift }
}

/// A line of the note and what Tracko says about it.
private struct LogLineRow: View {
    @Binding var text: String
    let line: NoteText
    let role: NoteLine
    let notes: [LineNote]
    let placeholder: String
    let startsLift: Bool
    let unit: WeightUnit
    @Binding var focusedLine: NoteText.ID?
    var onReturn: () -> Void
    var onDeleteEmpty: () -> Void
    var onPasteLines: ([String]) -> Void
    var onUseSuggestion: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            NoteLineField(
                text: $text,
                id: line.id,
                focusedLine: $focusedLine,
                placeholder: placeholder,
                weight: role.isName ? .semibold : .regular,
                onReturn: onReturn,
                onDeleteEmpty: onDeleteEmpty,
                onPasteLines: onPasteLines
            )
            ForEach(Array(notes.enumerated()), id: \.offset) { _, note in
                LineNoteView(note: note, unit: unit, onUseSuggestion: onUseSuggestion)
            }
        }
        .padding(.top, startsLift ? Space.l : 0)
        .padding(.bottom, notes.isEmpty ? 0 : Space.s)
    }
}

/// What Tracko says under a line (`LineNote`).
private struct LineNoteView: View {
    let note: LineNote
    let unit: WeightUnit
    var onUseSuggestion: (String) -> Void

    var body: some View {
        switch note {
        case .lastTime(let previous, let next):
            VStack(alignment: .leading, spacing: 2) {
                Text("\(DayText.relative(previous.date)): \(previous.session.summary(unit: unit).keptTogether)")
                    .foregroundStyle(Theme.textSecondary)
                Text("Next: \(next.summary(unit: unit).keptTogether)")
                    .foregroundStyle(Theme.textPrimary)
            }
            .typeRole(.caption)
            .accessibilityElement(children: .combine)

        case .firstTime:
            Text("First time logged. Next time it opens with a number to beat.")
                .typeRole(.caption)
                .foregroundStyle(Theme.textTertiary)

        case .toBeat(let done, let target, let need, let previousDate):
            VStack(alignment: .leading, spacing: Space.s) {
                TargetBar(fraction: target > 0 ? done / target : 0)
                Text(toBeatText(done: done, target: target, need: need, day: DayText.relative(previousDate)))
                    .typeRole(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.top, Space.xs)

        case .verdict(let verdict):
            HStack(alignment: .firstTextBaseline, spacing: Space.s) {
                Text(verdict.number)
                    .typeRole(.rowTitle)
                    // Green is growth; a dip is recovery, in neutral colour (§7.3).
                    .foregroundStyle(verdict.trend == .up ? Theme.accent : Theme.textSecondary)
                Text(verdict.reason)
                    .typeRole(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .accessibilityElement(children: .combine)

        case .unclear(let suggestion):
            if let suggestion {
                HStack(spacing: Space.s) {
                    Text("Try \(suggestion.keptTogether)")
                        .foregroundStyle(Theme.textTertiary)
                    Button("Use it") { onUseSuggestion(suggestion) }
                        .foregroundStyle(Theme.textPrimary)
                }
                .typeRole(.caption)
            } else {
                Text("Tracko can’t read this line yet. Sets look like 8 × 12, 11, 10.")
                    .typeRole(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }

        case .needsName:
            Text("Add the lift’s name above these sets.")
                .typeRole(.caption)
                .foregroundStyle(Theme.textTertiary)
        }
    }

    /// "10 reps ties Thursday. 11 beats it." once one set is left; the totals before that.
    private func toBeatText(done: Double, target: Double, need: LiftMath.LastSetNeed?, day: String) -> String {
        if let need, need.beat > 0 {
            if let tie = need.tie {
                return "\(tie) \(tie == 1 ? "rep" : "reps") ties \(day). \(need.beat) beats it."
            }
            return "\(need.beat) \(need.beat == 1 ? "rep" : "reps") beats \(day)."
        }
        let total = LiftMath.format(weight: target, unit: unit)
        let sofar = LiftMath.format(weight: done, unit: unit)
        return "\(day): \(total.keptTogether) in all. You’re at \(sofar.keptTogether)."
    }
}
