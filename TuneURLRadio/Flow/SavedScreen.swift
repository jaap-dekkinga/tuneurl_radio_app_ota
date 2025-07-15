import SwiftUI
import SwiftData

struct SavedScreen: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query private var savedURLs: [SavedURL]
    
    var body: some View {
        ZStack {
            Color(uiColor: .secondarySystemBackground).ignoresSafeArea()
            
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    ForEach(savedURLs) { savedURL in
                        Text(savedURL.url)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Saved URLs")
    }
}

#Preview {
    SavedScreen()
        .withPreviewEnv()
}
