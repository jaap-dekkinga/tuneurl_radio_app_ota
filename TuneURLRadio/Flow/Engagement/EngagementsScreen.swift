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
        List {
            ForEach(items) { item in
                Section {
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
                    .swipeActions(content: {
                        Button(role: .destructive) {
                            withAnimation {
                                engagementsStore.delete(item)
                            }
                        } label: {
                            Text("Delete")
                        }
                    })
                }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
        }
        .listSectionSpacing(16)
        .overlay {
            if items.isEmpty {
                ContentUnavailableView(
                    "No Saved Turls",
                    systemImage: "tray",
                    description: Text("You haven't saved any URLs yet.")
                )
            }
        }
        .navigationTitle("Saved Turls")
        .sheet(item: $selected) { item in
            if item.isWebEngagement, let url = item.engagementURL {
                SafariView(url: url)
            } else {
                EngagementScreen(savedEngagement: item)
                    .withEnv()
            }
        }
    }
}

#Preview {
    EngagementsScreen()
        .withPreviewEnv()
}
