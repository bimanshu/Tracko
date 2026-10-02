import SwiftUI
import UserNotifications

/// Scene 9, Future Wrapped. A card with their name and 90 days to go.
/// Notification permission is asked here, where it makes sense (§11).
struct WrappedScene: View {
    @Binding var name: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var nameFocused: Bool
    @State private var shown = false
    @State private var notifications: NotificationState = .unknown

    private enum NotificationState {
        case unknown, notAsked, on, off
    }

    private let checkpointDays = 90

    private var readyDate: String {
        let date = Calendar.current.date(byAdding: .day, value: checkpointDays, to: .now) ?? .now
        return date.formatted(.dateTime.day().month(.abbreviated))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            card
                .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            SceneHeadline("We'll tell you when it's ready.")
            notifyRow
                .frame(minHeight: 50)
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.m)
        .task {
            await refreshNotifications()
            if reduceMotion {
                shown = true
            } else {
                guard await Script.wait(0.2) else { return }
                withAnimation(Motion.settle) { shown = true }
            }
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Text("Your first Wrapped")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.chalkMuted)
            TextField("Your name", text: $name)
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.chalk)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($nameFocused)
            Spacer(minLength: 0)
            Text("\(checkpointDays)")
                .font(.score(96))
                .foregroundStyle(Theme.chalk)
            Text("days to go")
                .font(.headline)
                .foregroundStyle(Theme.chalkMuted)
            Text("Ready \(readyDate)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.target)
        }
        .padding(Space.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            ZStack(alignment: .bottomTrailing) {
                LinearGradient(colors: [Theme.slabRaised, Theme.slab], startPoint: .top, endPoint: .bottom)
                BodyFigure(growth: [.shoulders: 0.4, .chest: 0.4, .arms: 0.4])
                    .opacity(0.3)
                    .scaleEffect(0.75, anchor: .bottomTrailing)
                    .offset(x: 24, y: 8)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Theme.hairline)
        }
        .aspectRatio(9 / 16, contentMode: .fit)
        .rotation3DEffect(.degrees(shown ? 0 : 20), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
        .offset(y: shown ? 0 : 60)
        .opacity(shown ? 1 : 0)
    }

    @ViewBuilder
    private var notifyRow: some View {
        switch notifications {
        case .unknown:
            Color.clear
        case .notAsked:
            Button {
                Task { await requestNotifications() }
            } label: {
                Label("Notify me", systemImage: "bell")
            }
            .buttonStyle(SecondaryButtonStyle())
        case .on:
            Label("We'll tell you on \(readyDate).", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(Theme.chalk)
        case .off:
            Text("Notifications are off. You can turn them on in Settings.")
                .font(.subheadline)
                .foregroundStyle(Theme.chalkMuted)
        }
    }

    @MainActor
    private func refreshNotifications() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: notifications = .on
        case .denied: notifications = .off
        default: notifications = .notAsked
        }
    }

    @MainActor
    private func requestNotifications() async {
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        withAnimation(Motion.fade) {
            notifications = granted ? .on : .off
        }
    }
}

#Preview {
    WrappedScene(name: .constant(""))
        .background(Theme.ink)
}
