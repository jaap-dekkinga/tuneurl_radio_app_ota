import SwiftUI
import MediaPlayer
import TuneURL
import FRadioPlayer

@main
struct TuneURLRadioApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        StateManager.shared.configure()
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .withEnv()
                .onReceive(
                    NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
                ) { _ in
                    UIApplication.shared.endReceivingRemoteControlEvents()
                }
        }
    }
}

extension View {
    
    func withEnv() -> some View {
        self
            .modelContainer(Persistance.shared.container)
            .environment(StationsStore.shared)
            .environment(StateManager.shared)
            .environment(UserSettings.shared)
            .environment(EngagementsStore.shared)
            .environment(NotificationsStore.shared)
    }
    
    func withPreviewEnv() -> some View {
        self
            .modelContainer(Persistance.shared.previewContainer)
            .environment(StationsStore.shared)
            .environment(StateManager.shared)
            .environment(UserSettings.shared)
            .environment(EngagementsStore.shared)
            .environment(NotificationsStore.shared)
    }
}
