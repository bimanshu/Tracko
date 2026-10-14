import Foundation

/// The four onboarding pages (skill §11). Each one shows one thing Tracko does.
enum OnboardingPage: Int, CaseIterable, Identifiable, Hashable {
    case welcome, log, beat, grow

    var id: Int { rawValue }
    var isLast: Bool { self == Self.allCases.last }

    /// Debug builds can open on a page with the launch argument `-TrackoStartScene <0–3>`
    /// (CI screenshots use it).
    static var launchPage: OnboardingPage {
        #if DEBUG
        if let page = OnboardingPage(rawValue: UserDefaults.standard.integer(forKey: "TrackoStartScene")) {
            return page
        }
        #endif
        return .welcome
    }
}

extension OnboardingPage {
    /// The page's headline (≤ 7 words, §8). The welcome page's is set as "Welcome to" over the
    /// wordmark where the layout allows.
    var headline: String {
        switch self {
        case .welcome: return "Welcome to Tracko"
        case .log: return "Log it like a note"
        case .beat: return "Always know the number to beat"
        case .grow: return "Watch yourself get stronger"
        }
    }

    /// The line under the headline, in the user's units.
    func subline(_ demo: DemoContent) -> String {
        switch self {
        case .welcome: return "The gym log that talks back."
        case .log: return "Type \(demo.noteLine(demo.thursday).keptTogether) and Tracko does the maths."
        case .beat: return "Each lift shows what beats last time."
        case .grow: return "Proof you’re growing, week by week."
        }
    }

    /// The button: forward, then the finish.
    var buttonTitle: String { isLast ? "Start tracking" : "Continue" }
}

enum StorageKey {
    static let onboardingComplete = "onboardingComplete"
}
