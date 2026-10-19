import Foundation

/// Four weeks of believable history, for previews and the CI screenshots (`-TrackoScreen`), in
/// the user's units. The lateral raise is the onboarding's story (§7.1): Monday 8 kg × 10, 10, 10,
/// then Thursday 8 kg × 12, 11, 10.
enum DemoHistory {
    static let featuredKey = LiftName.key("Lateral raise")

    static func store(for screen: LaunchScreen? = nil, unit: WeightUnit = .preferred, now: Date = .now) -> WorkoutStore {
        var workouts = screen == .firstRun ? [] : history(unit: unit, now: now)
        if screen == .log {
            // Mid-workout: two sets of the raise in (one to go), the bench done.
            workouts.append(Workout(
                date: now,
                text: [
                    "Lateral raise",
                    "\(weight(8, 20, unit)) × 12, 11",
                    "Bench press",
                    "\(weight(62.5, 140, unit)) × 8, 8, 7",
                    "",
                ],
                isFinished: false,
                unit: unit
            ))
        } else if screen == .report {
            workouts.append(Workout(
                date: now,
                text: [
                    "Lateral raise",
                    "\(weight(8, 20, unit)) × 12, 11, 11",
                    "Bench press",
                    "\(weight(62.5, 140, unit)) × 8, 8, 7",
                    "Cable row",
                    "\(weight(52.5, 115, unit)) × 10, 10, 9",
                    "Face pull",
                    "\(weight(15, 35, unit)) × 15, 15, 15",
                ],
                unit: unit
            ))
        }
        return WorkoutStore(fileURL: nil, defaults: nil, unit: unit, workouts: workouts)
    }

    static func history(unit: WeightUnit, now: Date = .now, calendar: Calendar = .current) -> [Workout] {
        func day(_ offset: Int) -> Date {
            calendar.date(byAdding: .day, value: offset, to: now) ?? now
        }
        func session(_ days: Int, raise: (Double, Double, String), bench: (Double, Double, String), row: (Double, Double, String)) -> Workout {
            Workout(
                date: day(days),
                text: [
                    "Lateral raise",
                    "\(weight(raise.0, raise.1, unit)) × \(raise.2)",
                    "Bench press",
                    "\(weight(bench.0, bench.1, unit)) × \(bench.2)",
                    "Cable row",
                    "\(weight(row.0, row.1, unit)) × \(row.2)",
                ],
                unit: unit
            )
        }
        return [
            session(-25, raise: (8, 20, "8, 8, 8"), bench: (57.5, 125, "8, 8, 7"), row: (50, 110, "12, 10, 10")),
            session(-18, raise: (8, 20, "9, 9, 8"), bench: (60, 135, "8, 7, 7"), row: (50, 110, "12, 12, 10")),
            session(-7, raise: (8, 20, "10, 10, 10"), bench: (60, 135, "8, 8, 8"), row: (50, 110, "12, 12, 12")),
            session(-4, raise: (8, 20, "12, 11, 10"), bench: (62.5, 140, "8, 7, 7"), row: (52.5, 115, "12, 11, 10")),
        ]
    }

    /// The kg or lb weight, as typed: "8", "62.5".
    private static func weight(_ kg: Double, _ lb: Double, _ unit: WeightUnit) -> String {
        LiftMath.formatNumber(unit == .kg ? kg : lb, locale: Locale(identifier: "en_US_POSIX"))
    }
}
