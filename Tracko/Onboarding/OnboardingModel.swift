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

enum StorageKey {
    static let onboardingComplete = "onboardingComplete"
}
