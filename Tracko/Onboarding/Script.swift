import SwiftUI

/// Helpers for scripted scene animations (skill §10).
///
/// A scene plays with `.task(id: replay) { await play() }` and separates its steps with
/// `guard await Script.wait(x) else { return }`, so leaving or replaying a scene cancels cleanly.
enum Script {
    /// Sleeps for `seconds`. Returns false if the scene's task was cancelled.
    static func wait(_ seconds: Double) async -> Bool {
        do {
            try await Task.sleep(for: .seconds(seconds))
            return !Task.isCancelled
        } catch {
            return false
        }
    }

    /// Applies state changes without animating them, to rewind a scene before it replays.
    @MainActor
    static func reset(_ changes: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, changes)
    }
}
