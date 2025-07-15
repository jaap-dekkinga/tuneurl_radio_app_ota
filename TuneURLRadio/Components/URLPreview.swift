import SwiftUI
import LinkPresentation

struct URLPreview: UIViewRepresentable {
    
    let previewURL: URL
    @Binding var linkMetadata: LPLinkMetadata?
    
    func makeUIView(context: Context) -> LPLinkView {
        let view = CustomLinkView(url: previewURL)
        
        let store = URLPreviewsStore.shared
        Task {
            guard let metadata = await store.metadata(for: previewURL) else { return }
            await MainActor.run {
                view.metadata = metadata
                view.sizeToFit()
                self.linkMetadata = metadata
            }
        }
        
        return view
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: LPLinkView, context: Context) -> CGSize? {
        // The proposed width is the containing frame's width, if one is available use that width,
        // otherwise fallback to the custom view's intrinsic width
        let width = proposal.width ?? uiView.intrinsicContentSize.width
        
        // The proposed height is the containing frame's height which is going to be way to big.
        // So use the view's intrinsic height otherwise fallback to the smallest.
        let height = min(proposal.height ?? .infinity, uiView.intrinsicContentSize.height)
        return CGSize(width: width, height: height)
    }
    
    func updateUIView(_ uiView: LPLinkView, context: UIViewRepresentableContext<URLPreview>) {
    }
}

fileprivate class CustomLinkView: LPLinkView {
    override var intrinsicContentSize: CGSize {
        CGSize(width: super.intrinsicContentSize.width, height: super.intrinsicContentSize.height)
    }
}

@MainActor
class URLPreviewsStore {
    
    static let shared = URLPreviewsStore()
    
    private var memoryCache = NSCache<NSURL, LPLinkMetadata>()
    
    func metadata(for url: URL) async -> LPLinkMetadata? {
        if let cached = loadCachedMetadata(for: url) {
            memoryCache.setObject(cached, forKey: url as NSURL)
            return cached
        }
        
        do {
            let metadata = try await fetchMetadata(for: url)
            memoryCache.setObject(metadata, forKey: url as NSURL)
            cacheMetadata(metadata, for: url)
            return metadata
        } catch {
            print("Failed to fetch metadata: \(error)")
            return nil
        }
    }
    
    func prefetch(for url: URL) {
        Task {
            _ = await metadata(for: url)
        }
    }
    
    // MARK: - Caching
    private func cacheMetadata(_ metadata: LPLinkMetadata, for url: URL) {
        let fileURL = cacheURL(for: url)
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: metadata, requiringSecureCoding: true)
            try data.write(to: fileURL)
        } catch {
            print("Error saving metadata cache: \(error)")
        }
    }
    
    private func loadCachedMetadata(for url: URL) -> LPLinkMetadata? {
        let fileURL = cacheURL(for: url)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: LPLinkMetadata.self, from: data)
        } catch {
            print("Error loading metadata cache: \(error)")
            return nil
        }
    }
    
    private func cacheURL(for url: URL) -> URL {
        let safeName = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        let baseDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let folderURL = baseDir.appendingPathComponent("link-previews")
        
        // Ensure the folder exists
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        
        return folderURL.appendingPathComponent(safeName)
    }
    
    // MARK: - Fetch
    private func fetchMetadata(for url: URL) async throws -> LPLinkMetadata {
        return try await withCheckedThrowingContinuation { continuation in
            let provider = LPMetadataProvider()
            provider.startFetchingMetadata(for: url) { metadata, error in
                if let metadata = metadata {
                    continuation.resume(returning: metadata)
                } else {
                    continuation.resume(throwing: error ?? URLError(.badURL))
                }
            }
        }
    }
}
