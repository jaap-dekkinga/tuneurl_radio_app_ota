import SwiftUI
import SwiftData
import Kingfisher
import LinkPresentation

struct EngagementCard: View {
    
    @Environment(\.modelContext) private var context
    @Environment(DataStore.self) private var dataStore
    
    @State private var metadata: LPLinkMetadata?
    @State private var image: UIImage?
    
    let item: SavedEngagement
    let previewsStore = URLPreviewsStore.shared
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                Image(uiImage: image ?? .stationLogo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Group {
                    if item.engagementURL == nil, let title = item.engagementInfo {
                        Text(title)
                    } else if let title = metadata?.title {
                        Text(title)
                    }
                }
                .font(.headline)
                .lineLimit(2)
                
                if let station = dataStore.stations.first(where: { $0.id == item.sourceStationId }) {
                    SourceInfo(station)
                }
                
                Text(item.saveDate.formatted())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contextMenu {
            Button(role: .destructive) {
                delete()
            } label: {
                Text("Delete")
            }
        }
        .task {
            guard let url = item.engagementURL else { return }
            if let cachedImage = KingfisherManager.shared.cache.retrieveImageInMemoryCache(
                forKey: url.absoluteString
            ) {
                self.image = cachedImage
            }
            
            metadata = await previewsStore.metadata(for: url)
            if image == nil {
                let imageProvider = metadata?.imageProvider
                imageProvider?.loadObject(ofClass: UIImage.self) { image, error in
                    guard let image = image as? UIImage else { return }
                    self.image = image
                    KingfisherManager.shared.cache.store(
                        image,
                        forKey: url.absoluteString
                    )
                }
            }
        }
    }
    
    @ViewBuilder private func SourceInfo(_ station: Station) -> some View {
        HStack {
            ZStack {
                Color.white
                VStack {
                    if let imageURL = station.imageURL {
                        KFImage(imageURL)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image("station-logo")
                            .resizable()
                            .scaledToFit()
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(width: 24, height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            
            Text(station.name)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func delete() {
        context.delete(item)
        do {
            try context.save()
        } catch {
            fatalError("Could not delete engagement: \(error.localizedDescription)")
        }
    }
}

#Preview {
    EngagementsScreen()
        .withPreviewEnv()
}
