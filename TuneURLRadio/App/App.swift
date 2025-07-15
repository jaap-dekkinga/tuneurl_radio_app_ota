import SwiftUI
import SwiftData

@main
struct TuneURLRadioApp: App {
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .withEnv()
        }
    }
}

extension View {
    
    func withEnv() -> some View {
        self
            .modelContainer(Persistance.shared.container)
            .environment(DataStore.shared)
            .environment(CurrentPlayManager.shared)
    }
    
    func withPreviewEnv() -> some View {
        self
            .modelContainer(Persistance.shared.previewContainer)
            .environment(DataStore.shared)
            .environment(CurrentPlayManager.shared)
    }
}
