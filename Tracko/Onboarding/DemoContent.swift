import Foundation

/// Demo numbers for the onboarding story, in the user's units (§7.5).
/// The lb version uses a real dumbbell (20 lb), and percentages come out identical.
struct DemoContent {
    let unit: WeightUnit

    init(unit: WeightUnit = .preferred) {
        self.unit = unit
    }

    // MARK: The lateral raise story (§7.1 reference example)

    let exerciseName = "Lateral raise"
    let mondayReps = [10, 10, 10]
    let thursdayReps = [12, 11, 10]
    /// Today, in scene 3: the last set beats Thursday by one rep.
    let todayReps = [12, 11, 11]

    var weight: Double { unit == .kg ? 8 : 20 }
    /// One step up the dumbbell rack.
    var weightStep: Double { unit == .kg ? 1 : 5 }
    var weightText: String { LiftMath.format(weight: weight, unit: unit) }

    var monday: LiftSession { LiftSession(weight: weight, reps: mondayReps) }
    var thursday: LiftSession { LiftSession(weight: weight, reps: thursdayReps) }
    var today: LiftSession { LiftSession(weight: weight, reps: todayReps) }

    func weightString(_ value: Double) -> String {
        LiftMath.format(weight: value, unit: unit)
    }

    // MARK: The notes page (scene 1)

    struct NoteLine: Identifiable {
        let id: Int
        let text: String
        let isHeading: Bool
    }

    /// Two weeks of push/pull/legs, typed the way people type in Notes, ending last week.
    var notesPage: [NoteLine] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today) // 1 is Sunday
        let daysSinceMonday = (weekday + 5) % 7
        let start = calendar.date(byAdding: .day, value: -(daysSinceMonday + 14), to: today) ?? today

        var lines: [NoteLine] = []
        for week in 0..<2 {
            for dayIndex in 0..<6 {
                let template = Self.templates[dayIndex % Self.templates.count]
                let session = week * 6 + dayIndex
                let date = calendar.date(byAdding: .day, value: week * 7 + dayIndex, to: start) ?? start
                let day = date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
                lines.append(NoteLine(id: lines.count, text: "\(day) · \(template.day)", isHeading: true))
                for lift in template.lifts {
                    let reps = lift.reps.enumerated().map { set, count in
                        count + ((session + set) % 4 == 0 ? 1 : 0)
                    }
                    lines.append(NoteLine(id: lines.count, text: lift.line(unit: unit, reps: reps), isHeading: false))
                }
            }
        }
        return lines
    }

    private struct DemoLift {
        let name: String
        let kg: Double
        let lb: Double
        let reps: [Int]

        func line(unit: WeightUnit, reps: [Int]) -> String {
            let list = reps.map { String($0) }.joined(separator: ", ")
            let weight = unit == .kg ? kg : lb
            guard weight > 0 else { return "\(name) \(list)" }
            return "\(name) \(LiftMath.formatNumber(weight)) x \(list)"
        }
    }

    private struct DayTemplate {
        let day: String
        let lifts: [DemoLift]
    }

    private static let templates: [DayTemplate] = [
        DayTemplate(day: "Push", lifts: [
            DemoLift(name: "Bench", kg: 60, lb: 135, reps: [8, 8, 7]),
            DemoLift(name: "Incline DB", kg: 22, lb: 50, reps: [10, 9, 8]),
            DemoLift(name: "Lateral raise", kg: 8, lb: 20, reps: [10, 10, 10]),
            DemoLift(name: "Pushdown", kg: 25, lb: 55, reps: [12, 12, 10]),
        ]),
        DayTemplate(day: "Pull", lifts: [
            DemoLift(name: "Pull-ups", kg: 0, lb: 0, reps: [8, 7, 6]),
            DemoLift(name: "Row", kg: 50, lb: 110, reps: [10, 10, 9]),
            DemoLift(name: "Curl", kg: 12, lb: 25, reps: [12, 10, 9]),
            DemoLift(name: "Face pull", kg: 15, lb: 35, reps: [15, 15, 12]),
        ]),
        DayTemplate(day: "Legs", lifts: [
            DemoLift(name: "Squat", kg: 80, lb: 185, reps: [6, 6, 5]),
            DemoLift(name: "RDL", kg: 70, lb: 155, reps: [8, 8, 8]),
            DemoLift(name: "Leg press", kg: 140, lb: 310, reps: [12, 10, 10]),
            DemoLift(name: "Calf raise", kg: 60, lb: 135, reps: [15, 15, 12]),
        ]),
    ]
}
