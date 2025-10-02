import SwiftUI
import SwiftData
import Kingfisher
import LinkPresentation

struct EngagementListCard: View {
    
    @Environment(StationsStore.self) private var stationsStore
    
    @State private var metadata: LPLinkMetadata?
    @State private var image: UIImage?
    
    let infoURL: URL?
    let info: String?
    let stationId: Int?
    let date: Date?
    private let previewsStore = URLPreviewsStore.shared
    
    var body: some View {
        HStack(spacing: 8) {
            Image(uiImage: image ?? .stationLogo)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100)
                .clipShape(
                    UnevenRoundedRectangle(
                        cornerRadii: .init(
                            topLeading: 8,
                            bottomLeading: 8
                        ),
                        style: .continuous
                    )
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Group {
                    if let title = info?.trimmed.nilIfEmpty {
                        Text(title)
                    } else if let title = metadata?.title {
                        Text(title)
                    } else {
                        Text("No Info")
                    }
                }
                .font(.headline)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if let station = stationsStore.stations.first(where: { $0.id == stationId }) {
                    SourceInfo(station)
                }
                
                if let date {
                    Text(date.formatted())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 6)
            .padding(.trailing, 8)
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .task {
            guard let url = infoURL else { return }
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
}

#Preview {
    SavedEngagementsScreen()
        .withPreviewEnv()
}
