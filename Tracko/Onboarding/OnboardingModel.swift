import Foundation
import Observation

enum OnboardingScene: Int, CaseIterable, Identifiable {
    case hook, noteToVerdict, numberToBeat, tryIt, grow, proof, goal, history, wrapped

    var id: Int { rawValue }

    /// Story scenes can be skipped; data scenes can't (§11).
    var isStory: Bool { rawValue < OnboardingScene.goal.rawValue }
}

enum Goal: String, CaseIterable, Identifiable {
    case build, loseFat, both

    var id: Self { self }

    var title: String {
        switch self {
        case .build: return "Build muscle"
        case .loseFat: return "Lose fat"
        case .both: return "Both"
        }
    }

    var detail: String {
        switch self {
        case .build: return "Beat your numbers week on week."
        case .loseFat: return "Get lighter without getting weaker."
        case .both: return "Recomp: hold your strength, trim your waist."
        }
    }
}

enum HistoryChoice: String, CaseIterable, Identifiable {
    case importNotes, startFresh

    var id: Self { self }

    var title: String {
        switch self {
        case .importNotes: return "Yes, in notes or a notebook"
        case .startFresh: return "Not yet"
        }
    }

    var detail: String {
        switch self {
        case .importNotes: return "Paste or snap them. We'll find your progress."
        case .startFresh: return "Log one recent lift. That's your Day 1."
        }
    }
}

enum StorageKey {
    static let onboardingComplete = "onboardingComplete"
    static let goal = "goal"
    static let history = "history"
    static let name = "name"
}

@Observable
final class OnboardingModel {
    enum Direction {
        case forward, backward
    }

    private(set) var scene: OnboardingScene
    private(set) var direction: Direction = .forward
    var goal: Goal?
    var history: HistoryChoice?
    var name = ""

    init(scene: OnboardingScene = .hook) {
        self.scene = scene
    }

    var isFirst: Bool { scene == OnboardingScene.allCases.first }
    var isLast: Bool { scene == OnboardingScene.allCases.last }

    var canContinue: Bool {
        switch scene {
        case .goal: return goal != nil
        case .history: return history != nil
        default: return true
        }
    }

    func next() {
        guard let next = OnboardingScene(rawValue: scene.rawValue + 1) else { return }
        direction = .forward
        scene = next
    }

    func back() {
        guard let previous = OnboardingScene(rawValue: scene.rawValue - 1) else { return }
        direction = .backward
        scene = previous
    }

    /// Skip jumps to the goal scene: story scenes are optional, data scenes are not.
    func skipStory() {
        direction = .forward
        scene = .goal
    }

    /// Debug builds can open on a scene with the launch argument `-TrackoStartScene <index>`.
    static func launch() -> OnboardingModel {
        #if DEBUG
        let index = UserDefaults.standard.integer(forKey: "TrackoStartScene")
        if let scene = OnboardingScene(rawValue: index) {
            return OnboardingModel(scene: scene)
        }
        #endif
        return OnboardingModel()
    }
}
