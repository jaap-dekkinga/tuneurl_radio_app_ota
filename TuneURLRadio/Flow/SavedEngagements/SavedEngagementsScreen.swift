import SwiftUI
import SwiftData
import Kingfisher

struct SavedEngagementsScreen: View {
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Environment(\.modelContext) private var context
    @Environment(StationsStore.self) private var stationsStore
    @Environment(EngagementsStore.self) private var engagementsStore
    
    @Query(sort: \SavedEngagement.createAt, order: .reverse)
    private var items: [SavedEngagement]
    
    @State private var selected: SavedEngagement?
    
    var body: some View {
        List {
            ForEach(items) { item in
                Section {
                    Button {
                        selected = item
                        ReportAction.acted(item.engagement).report()
                    } label: {
                        EngagementListCard(
                            infoURL: item.engagementURL,
                            info: item.engagementDescription,
                            stationId: item.sourceStationId,
                            date: item.heardAt
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
                ViewEngagementScreen(savedEngagement: item)
                    .withEnv()
            }
        }
    }
}

#Preview {
    SavedEngagementsScreen()
        .withPreviewEnv()
}
