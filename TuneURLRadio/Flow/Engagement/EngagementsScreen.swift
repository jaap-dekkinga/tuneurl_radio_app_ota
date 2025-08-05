import SwiftUI
import SwiftData
import Kingfisher

struct EngagementsScreen: View {
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Environment(\.modelContext) private var context
    @Environment(StationsStore.self) private var stationsStore
    @Environment(EngagementsStore.self) private var engagementsStore
    
    @Query(sort: \SavedEngagement.saveDate, order: .reverse)
    private var items: [SavedEngagement]
    
    @State private var selected: SavedEngagement?
    
    var body: some View {
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
                        EngagementCard(
                            infoURL: item.engagementURL,
                            info: item.engagementDescription,
                            stationId: item.sourceStationId,
                            date: item.saveDate
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            engagementsStore.delete(item)
                        } label: {
                            Text("Delete")
                        }
                    }
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
        .background(Color(uiColor: .secondarySystemBackground))
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
