import SwiftUI
import SwiftData
import Kingfisher

struct EngagementsScreen: View {
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Environment(\.modelContext) private var modelContext
    @Environment(DataStore.self) private var dataStore
    
    @Query(sort: \SavedEngagement.saveDate)
    private var items: [SavedEngagement]
    
    @State private var selected: SavedEngagement?
    
    var body: some View {
        ZStack {
            Color(uiColor: .secondarySystemBackground).ignoresSafeArea()
            
            ScrollView {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: 12),
                        count: horizontalSizeClass == .compact ? 2 : 4
                    ),
                    spacing: 12
                ) {
                    ForEach(items) { item in
                        Button {
                            selected = item
                        } label: {
                            EngagementCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .overlay {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No Saved URLs",
                        systemImage: "tray",
                        description: Text("You haven't saved any URLs yet.")
                    )
                }
            }
        }
        .navigationTitle("Saved URLs")
        .sheet(item: $selected) { item in
            EngagementScreen(savedEngagement: item)
                .withEnv()
        }
    }
}

#Preview {
    EngagementsScreen()
        .withPreviewEnv()
}
