import Foundation

/// A set as it was typed. The weight keeps its unit when one was written ("60 kg").
struct ParsedSet: Equatable, Sendable {
    var weight: Double
    var unit: WeightUnit?
    var reps: Int
}

/// What one line of a workout note says (skill §12).
enum NoteLine: Equatable, Sendable {
    case blank
    /// A line of words: a lift's name, or a heading or comment ("Push day", "felt easy").
    case name(String)
    /// Sets: "8 × 12, 11, 10", "60 kg 3 × 10", "3 × 10 @ 60", "100 × 5".
    case sets([ParsedSet])
    /// A name and its sets on one line: "Bench 60 × 8, 8, 7".
    case nameAndSets(String, [ParsedSet])
    /// Numbers Tracko couldn't read, with the line as it was probably meant.
    case unclear(suggestion: String?)
}

/// Reads lines the way lifters type them in Notes. The forms:
/// - `weight × reps, reps, …`: straight sets at one weight. "8 × 12, 11, 10", "8kg x 12/11/10".
///   A single "100 × 5" is one set of 5 at 100.
/// - `weight sets × reps`: "60 kg 3 × 10".
/// - `sets × reps @ weight`: "3 × 10 @ 60", "3x10 at 60kg".
/// A name may come first ("Bench 60 × 8, 8, 7"), words after the sets are a comment, and × can be
/// typed as x or *. Anything else with numbers in it is unclear, never an error.
enum NoteParser {
    static func parse(_ line: String) -> NoteLine {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return .blank }
        guard let firstDigit = trimmed.firstIndex(where: \.isASCIIDigit) else {
            return .name(cleanName(trimmed))
        }
        let name = cleanName(String(trimmed[..<firstDigit]))
        var tokens = tokenize(String(trimmed[firstDigit...]))

        // Words after the numbers are a comment ("60 × 8, 8, 7 easy").
        var hadComment = false
        while let last = tokens.last, last.isWord || last == .separator {
            if last.isWord { hadComment = true }
            tokens.removeLast()
        }
        if let sets = readSets(tokens) {
            return name.isEmpty ? .sets(sets) : .nameAndSets(name, sets)
        }
        // A name with a number in it, like "Incline 30° press", is still a name.
        if hadComment, !name.isEmpty, !tokens.contains(.times), !tokens.contains(.at) {
            return .name(cleanName(trimmed))
        }
        return .unclear(suggestion: suggestion(name: name, tokens: tokens))
    }

    // MARK: Tokens

    enum Token: Equatable {
        case number(Double)
        case unit(WeightUnit)
        case times
        case at
        case separator
        case word(String)

        var isWord: Bool {
            if case .word = self { return true }
            return false
        }
    }

    static func tokenize(_ text: String) -> [Token] {
        let characters = Array(text)
        var tokens: [Token] = []
        var index = 0
        while index < characters.count {
            let character = characters[index]
            if character.isASCIIDigit {
                var digits = ""
                while index < characters.count {
                    let next = characters[index]
                    let isDecimalPoint = next == "." && index + 1 < characters.count && characters[index + 1].isASCIIDigit
                    guard next.isASCIIDigit || isDecimalPoint else { break }
                    digits.append(next)
                    index += 1
                }
                tokens.append(.number(Double(digits) ?? 0))
            } else if character.isLetter {
                var word = ""
                while index < characters.count, characters[index].isLetter || characters[index] == "-" {
                    word.append(characters[index])
                    index += 1
                }
                switch word.lowercased() {
                case "x": tokens.append(.times)
                case "at": tokens.append(.at)
                case "kg", "kgs", "kilo", "kilos": tokens.append(.unit(.kg))
                case "lb", "lbs", "pound", "pounds": tokens.append(.unit(.lb))
                default: tokens.append(.word(word))
                }
            } else {
                switch character {
                case "×", "*": tokens.append(.times)
                case "@": tokens.append(.at)
                case ",", "/", ";": tokens.append(.separator)
                default: break
                }
                index += 1
            }
        }
        return tokens
    }

    // MARK: Sets

    private struct Cursor {
        let tokens: [Token]
        var index = 0

        var isAtEnd: Bool { index == tokens.count }

        mutating func number() -> Double? {
            guard index < tokens.count, case .number(let value) = tokens[index] else { return nil }
            index += 1
            return value
        }

        mutating func unit() -> WeightUnit? {
            guard index < tokens.count, case .unit(let unit) = tokens[index] else { return nil }
            index += 1
            return unit
        }

        mutating func take(_ token: Token) -> Bool {
            guard index < tokens.count, tokens[index] == token else { return false }
            index += 1
            return true
        }

        mutating func skipSeparators() {
            while take(.separator) {}
        }
    }

    static func readSets(_ tokens: [Token]) -> [ParsedSet]? {
        guard !tokens.isEmpty, !tokens.contains(where: \.isWord) else { return nil }

        // sets × reps @ weight
        var cursor = Cursor(tokens: tokens)
        if let count = cursor.number(), cursor.take(.times), let reps = cursor.number(), cursor.take(.at),
           let weight = cursor.number() {
            let unit = cursor.unit()
            if cursor.isAtEnd { return straightSets(count: count, reps: reps, weight: weight, unit: unit) }
        }

        // weight sets × reps
        cursor = Cursor(tokens: tokens)
        if let weight = cursor.number() {
            let unit = cursor.unit()
            if let count = cursor.number(), cursor.take(.times), let reps = cursor.number(), cursor.isAtEnd {
                return straightSets(count: count, reps: reps, weight: weight, unit: unit)
            }
        }

        // weight × reps, reps, …
        cursor = Cursor(tokens: tokens)
        if let weight = cursor.number() {
            var unit = cursor.unit()
            if cursor.take(.times) {
                var reps: [Double] = []
                cursor.skipSeparators()
                while let value = cursor.number() {
                    reps.append(value)
                    cursor.skipSeparators()
                }
                if unit == nil { unit = cursor.unit() }
                if cursor.isAtEnd, !reps.isEmpty, isWeight(weight), reps.allSatisfy(isReps) {
                    return reps.map { ParsedSet(weight: weight, unit: unit, reps: Int($0)) }
                }
            }
        }
        return nil
    }

    private static func straightSets(count: Double, reps: Double, weight: Double, unit: WeightUnit?) -> [ParsedSet]? {
        guard isWhole(count), (1...20).contains(count), isReps(reps), isWeight(weight) else { return nil }
        return Array(repeating: ParsedSet(weight: weight, unit: unit, reps: Int(reps)), count: Int(count))
    }

    private static func isWhole(_ value: Double) -> Bool { value == value.rounded() }
    private static func isReps(_ value: Double) -> Bool { isWhole(value) && (1...200).contains(value) }
    private static func isWeight(_ value: Double) -> Bool { value > 0 && value <= 2000 }

    // MARK: Suggestions

    /// "8 12 11 10" was probably "8 × 12, 11, 10".
    private static func suggestion(name: String, tokens: [Token]) -> String? {
        let numbers = tokens.compactMap { token -> Double? in
            if case .number(let value) = token { return value }
            return nil
        }
        guard numbers.count >= 2, !tokens.contains(.times), !tokens.contains(.at),
              isWeight(numbers[0]), numbers.dropFirst().allSatisfy(isReps)
        else { return nil }
        let unit = tokens.compactMap { token -> WeightUnit? in
            if case .unit(let unit) = token { return unit }
            return nil
        }.first
        let weight = LiftMath.formatNumber(numbers[0], locale: Locale(identifier: "en_US_POSIX"))
            + (unit.map { " \($0.rawValue)" } ?? "")
        let reps = numbers.dropFirst().map { String(Int($0)) }.joined(separator: ", ")
        let sets = "\(weight) × \(reps)"
        return name.isEmpty ? sets : "\(name) \(sets)"
    }

    /// Trims spaces and trailing punctuation: "Bench:" → "Bench".
    private static func cleanName(_ text: String) -> String {
        text.trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: ":-–—")))
    }
}

extension Character {
    var isASCIIDigit: Bool { isASCII && isNumber }
}

/// Lift names match however they're typed: "Lateral raises", "lateral  raise" and "Lateral Raise"
/// are one lift.
enum LiftName {
    static func key(_ name: String) -> String {
        name.lowercased()
            .split(whereSeparator: \.isWhitespace)
            .map { singular(String($0)) }
            .joined(separator: " ")
    }

    private static func singular(_ word: String) -> String {
        guard word.count > 3 else { return word }
        if word.hasSuffix("sses") { return String(word.dropLast(2)) }
        if word.hasSuffix("s"), !word.hasSuffix("ss") { return String(word.dropLast()) }
        return word
    }
}
