import SwiftUI

/// The growth report after Finish (skill §6.1, §12): one block per lift, the verdict number first,
/// then the plain reason and the next target. Every session ends with an answer (rule 5).
struct ReportScreen: View {
    let workoutID: Workout.ID
    var onDone: () -> Void

    @Environment(WorkoutStore.self) private var store
    @State private var hasAppeared = false

    var body: some View {
        let rows = store.workout(workoutID).map(rows(for:)) ?? []
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.xl) {
                    VStack(alignment: .leading, spacing: Space.s) {
                        PageHeadline("Workout done", alignment: .left)
                        PageSubline(summary(rows), alignment: .left)
                    }
                    VStack(spacing: Space.m) {
                        ForEach(rows) { row in
                            ReportRowView(row: row, unit: store.unit)
                        }
                    }
                }
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.xxl)
                .padding(.bottom, Space.xl)
            }
            Button("Done", action: onDone)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, Space.m)
                .padding(.bottom, Space.l)
        }
        .background(Theme.bgPage)
        .sensoryFeedback(.success, trigger: hasAppeared)
        .onAppear { hasAppeared = true }
    }

    private func rows(for workout: Workout) -> [ReportRow] {
        workout.loggedLifts(unit: store.unit).map { lift in
            let previous = store.previous(lift.key, before: workout)
            return ReportRow(
                id: lift.key,
                name: lift.name,
                session: lift.session,
                verdict: previous.map { LiftMath.verdict(from: $0.session, to: lift.session, unit: store.unit) },
                next: LiftMath.nextTarget(after: lift.session)
            )
        }
    }

    private func summary(_ rows: [ReportRow]) -> String {
        let gains = rows.filter { $0.verdict?.trend == .up }.count
        let lifts = "\(rows.count) \(rows.count == 1 ? "lift" : "lifts")"
        guard rows.contains(where: { $0.verdict != nil }) else { return "\(lifts) logged. Your numbers to beat start now." }
        return "\(lifts) logged, \(gains) up on last time."
    }
}

struct ReportRow: Identifiable, Equatable {
    let id: String
    let name: String
    let session: LiftSession
    /// Nil the first time a lift is logged.
    let verdict: Verdict?
    let next: LiftSession
}

private struct ReportRowView: View {
    let row: ReportRow
    let unit: WeightUnit

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Text(row.name)
                .typeRole(.rowTitle)
                .foregroundStyle(Theme.textPrimary)
            if let verdict = row.verdict {
                Text(verdict.number)
                    .typeRole(.score)
                    // Green is growth; a dip is recovery, in neutral colour (§7.3).
                    .foregroundStyle(verdict.trend == .up ? Theme.accent : Theme.textSecondary)
                Text(verdict.reason)
                    .typeRole(.body)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                Text("First log: \(row.session.summary(unit: unit).keptTogether). Next time it opens with a number to beat.")
                    .typeRole(.body)
                    .foregroundStyle(Theme.textSecondary)
            }
            Text("Next: \(row.next.summary(unit: unit).keptTogether)")
                .typeRole(.caption)
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, Space.xs)
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}
