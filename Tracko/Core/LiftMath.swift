import Foundation

// The maths, single source of truth (skill §7). Keep the formulas here and in the skill identical,
// and keep the reference examples true in LiftMathTests.

enum WeightUnit: String, CaseIterable, Codable, Sendable {
    case kg, lb

    /// lb where the locale measures in US units, kg everywhere else (§7.5).
    static var preferred: WeightUnit {
        Locale.current.measurementSystem == .us ? .lb : .kg
    }
}

struct LiftSet: Hashable, Sendable {
    var weight: Double
    var reps: Int
}

/// One exercise in one workout: its working sets.
struct LiftSession: Hashable, Sendable {
    var sets: [LiftSet]

    init(sets: [LiftSet]) {
        self.sets = sets
    }

    /// Straight sets at one weight, e.g. 8 kg × 12, 11, 10.
    init(weight: Double, reps: [Int]) {
        self.sets = reps.map { LiftSet(weight: weight, reps: $0) }
    }

    var volume: Double { LiftMath.volume(sets) }
    var totalReps: Int { LiftMath.totalReps(sets) }
    var estimatedOneRepMax: Double { LiftMath.estimatedOneRepMax(sets) }
    var topWeight: Double { sets.map(\.weight).max() ?? 0 }

    /// The weight, when every set used the same one.
    var singleWeight: Double? {
        guard let first = sets.first?.weight,
              sets.allSatisfy({ abs($0.weight - first) < LiftMath.tolerance })
        else { return nil }
        return first
    }

    /// "8 kg × 12, 11, 10"
    func summary(unit: WeightUnit) -> String {
        let reps = sets.map { String($0.reps) }.joined(separator: ", ")
        return "\(LiftMath.format(weight: topWeight, unit: unit)) × \(reps)"
    }
}

/// The answer after a lift: number first, then the plain reason (§8).
struct Verdict: Equatable, Sendable {
    enum Trend: Equatable, Sendable {
        case up, level, down
    }

    let percent: Int
    let reason: String

    var trend: Trend {
        if percent > 0 { return .up }
        if percent < 0 { return .down }
        return .level
    }

    /// "+10%"
    var number: String { LiftMath.formatPercent(percent) }

    /// "+10%. You did 3 extra reps at the same weight."
    var sentence: String { "\(number). \(reason)" }
}

enum LiftMath {
    static let tolerance = 1e-9
    static let poundsPerKilogram = 2.20462262

    // MARK: Per lift (§7.1)

    /// Weight × reps, summed across working sets.
    static func volume(_ sets: [LiftSet]) -> Double {
        sets.reduce(0) { $0 + $1.weight * Double($1.reps) }
    }

    static func totalReps(_ sets: [LiftSet]) -> Int {
        sets.reduce(0) { $0 + $1.reps }
    }

    /// Epley: weight × (1 + reps ÷ 30).
    static func estimatedOneRepMax(weight: Double, reps: Int) -> Double {
        weight * (1 + Double(reps) / 30)
    }

    /// Estimated 1RM of the best set.
    static func estimatedOneRepMax(_ sets: [LiftSet]) -> Double {
        sets.map { estimatedOneRepMax(weight: $0.weight, reps: $0.reps) }.max() ?? 0
    }

    /// (new − old) ÷ old × 100.
    static func percentChange(from old: Double, to new: Double) -> Double {
        guard old > 0 else { return 0 }
        return (new - old) / old * 100
    }

    /// Percent change rounded to the nearest whole number, for display.
    static func displayPercent(from old: Double, to new: Double) -> Int {
        Int(percentChange(from: old, to: new).rounded())
    }

    // MARK: Verdict (§6.1, §7.2, §7.3)

    /// Compares a lift with the last session of the same exercise.
    /// Same weight: volume change, explained in reps. Different weight: estimated 1RM change leads.
    static func verdict(from previous: LiftSession, to current: LiftSession, unit: WeightUnit) -> Verdict {
        let recovery = "Lighter day, that's recovery."

        if let before = previous.singleWeight,
           let after = current.singleWeight,
           abs(before - after) < tolerance {
            let percent = displayPercent(from: previous.volume, to: current.volume)
            let extra = current.totalReps - previous.totalReps
            let reason: String
            if extra > 0 {
                reason = "You did \(extra) extra \(extra == 1 ? "rep" : "reps") at the same weight."
            } else if extra == 0 {
                reason = "Same reps at the same weight. Add one next time."
            } else {
                reason = recovery
            }
            return Verdict(percent: percent, reason: reason)
        }

        let percent = displayPercent(from: previous.estimatedOneRepMax, to: current.estimatedOneRepMax)
        let reason: String
        if percent < 0 {
            reason = recovery
        } else if current.topWeight > previous.topWeight {
            reason = "You moved up to \(format(weight: current.topWeight, unit: unit))."
        } else {
            reason = "More reps at a lighter weight."
        }
        return Verdict(percent: percent, reason: reason)
    }

    // MARK: Number to beat (§6.2)

    struct LastSetNeed: Equatable, Sendable {
        /// Reps that exactly tie the target, when whole reps can.
        let tie: Int?
        /// Fewest reps that beat it.
        let beat: Int
    }

    /// What the last set needs at `weight` to tie or beat `target` volume, after the `done` sets.
    static func lastSetNeed(target: Double, done: [LiftSet], weight: Double) -> LastSetNeed {
        let remaining = target - volume(done)
        guard weight > 0, remaining >= 0 else { return LastSetNeed(tie: nil, beat: 0) }
        let reps = remaining / weight
        let whole = reps.rounded()
        if abs(reps - whole) < 1e-6 {
            return LastSetNeed(tie: Int(whole), beat: Int(whole) + 1)
        }
        return LastSetNeed(tie: nil, beat: Int(reps.rounded(.down)) + 1)
    }

    /// The other route: one weight step up, with the fewest equal reps per set that beat `target`.
    static func goUpOption(target: Double, weight: Double, step: Double, sets: Int) -> LiftSession {
        let heavier = weight + step
        let perSet = target / (heavier * Double(max(sets, 1)))
        let reps = Int((perSet + tolerance).rounded(.down)) + 1
        return LiftSession(weight: heavier, reps: Array(repeating: reps, count: sets))
    }

    // MARK: Cut mode (§7.4)

    /// Estimated 1RM ÷ 7-day average bodyweight.
    static func relativeStrength(oneRepMax: Double, bodyweight: Double) -> Double {
        guard bodyweight > 0 else { return 0 }
        return oneRepMax / bodyweight
    }

    /// Rolling mean of the last 7 weigh-ins.
    static func trendWeight(_ weighIns: [Double]) -> Double? {
        let recent = weighIns.suffix(7)
        guard !recent.isEmpty else { return nil }
        return recent.reduce(0, +) / Double(recent.count)
    }

    /// Weekly change in trend weight as a % of bodyweight. A steady cut is about −0.5 to −1.
    static func weeklyPace(lastWeekTrend: Double, thisWeekTrend: Double) -> Double {
        percentChange(from: lastWeekTrend, to: thisWeekTrend)
    }

    // MARK: Honest growth (§6.3, §9.4)

    /// Growth on a slowing curve: fast early, flatter later. 0 at week 0, approaching 1.
    static func honestGrowth(week: Double, halfLifeWeeks: Double = 6) -> Double {
        guard week > 0 else { return 0 }
        return 1 - pow(0.5, week / halfLifeWeeks)
    }

    /// Growth so far as a share of the growth reached by week `total`, 0...1.
    static func honestProgress(week: Double, of total: Double) -> Double {
        let end = honestGrowth(week: total)
        guard end > 0 else { return 0 }
        return min(honestGrowth(week: week) / end, 1)
    }

    // MARK: Units and formatting (§7.5)

    static func convert(_ value: Double, from: WeightUnit, to: WeightUnit) -> Double {
        switch (from, to) {
        case (.kg, .lb): return value * poundsPerKilogram
        case (.lb, .kg): return value / poundsPerKilogram
        default: return value
        }
    }

    /// "8 kg", "22.5 lb"
    static func format(weight: Double, unit: WeightUnit, locale: Locale = .current) -> String {
        "\(formatNumber(weight, locale: locale)) \(unit.rawValue)"
    }

    /// At most one decimal place: 10.7, 240.
    static func formatNumber(_ value: Double, locale: Locale = .current) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)).locale(locale))
    }

    /// "+10%", "0%", "−3%" (with a true minus sign).
    static func formatPercent(_ value: Int) -> String {
        if value > 0 { return "+\(value)%" }
        if value < 0 { return "\u{2212}\(-value)%" }
        return "0%"
    }
}
