import Foundation

/// Demo numbers for the onboarding story, in the user's units (§7.5). The lb version uses real
/// dumbbells (20 lb, 25 lb), and every percentage comes out the same as in kg.
struct DemoContent {
    let unit: WeightUnit

    init(unit: WeightUnit = .preferred) {
        self.unit = unit
    }

    // MARK: The lateral raise story (§7.1 reference example)

    let exerciseName = "Lateral raise"
    let mondayReps = [10, 10, 10]
    let thursdayReps = [12, 11, 10]
    /// Today, on the number-to-beat page: the last set beats Thursday by one rep.
    let todayReps = [12, 11, 11]

    var weight: Double { unit == .kg ? 8 : 20 }

    var monday: LiftSession { LiftSession(weight: weight, reps: mondayReps) }
    var thursday: LiftSession { LiftSession(weight: weight, reps: thursdayReps) }
    var today: LiftSession { LiftSession(weight: weight, reps: todayReps) }

    /// A session typed the way people type it in Notes: "8 × 12, 11, 10".
    func noteLine(_ session: LiftSession) -> String {
        let reps = session.sets.map { String($0.reps) }.joined(separator: ", ")
        return "\(LiftMath.formatNumber(session.topWeight)) × \(reps)"
    }

    /// Monday → Thursday: "+10%. You did 3 extra reps at the same weight."
    var thursdayVerdict: Verdict { LiftMath.verdict(from: monday, to: thursday, unit: unit) }

    /// Thursday → today.
    var todayVerdict: Verdict { LiftMath.verdict(from: thursday, to: today, unit: unit) }

    /// What today's last set needs after the first two sets: 10 ties Thursday, 11 beats it.
    var lastSetNeed: LiftMath.LastSetNeed {
        LiftMath.lastSetNeed(target: thursday.volume, done: Array(today.sets.prefix(2)), weight: weight)
    }

    // MARK: Twelve weeks on (the growth page)

    let growthWeeks = 12
    /// Twelve weeks later: two dumbbell steps up, still about 10 reps.
    var weekTwelve: LiftSession { LiftSession(weight: unit == .kg ? 10 : 25, reps: [10, 10, 9]) }

    /// Estimated 1RM change from Monday to week 12.
    var growthPercent: Int {
        LiftMath.displayPercent(from: monday.estimatedOneRepMax, to: weekTwelve.estimatedOneRepMax)
    }

    /// The honest curve (§6.3): the share of the 12-week gain reached by each week, fast early
    /// and slower later.
    var growthCurve: [Double] {
        (0...growthWeeks).map { LiftMath.honestProgress(week: Double($0), of: Double(growthWeeks)) }
    }
}
