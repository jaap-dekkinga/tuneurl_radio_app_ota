import SwiftUI
import Kingfisher

// Sponsor ads from the station's own ad server (Revive Adserver at adserver.radiosalina.com),
// the same server and zones that ksal.com uses. Impressions and clicks are counted by Revive,
// so app traffic shows up in the station's existing reports (look for `loc` = ksal.com/app/ios/…).
//
// Zones on ksal.com (read 2026-11-18): 17 = 728×90, 5 = 288×100, 20 = 300×250, 2 = 234×60,
// 16 = 1110×180. Ask the station to create app-only zones if they want to sell app inventory
// separately, then change the ids below.

enum AdZone {
    static let leaderboard = 17      // 728×90, iPad top banners
    static let mobileBanner = 5      // 288×100, iPhone banners
    static let rectangle = 20        // 300×250, in-feed and in-article
}

/// Where an ad appears. The zone depends on the screen width.
enum AdPlacement: String {
    case homeTop = "home-top"
    case homeFeed = "home-feed"
    case article = "article"
    case sports = "sports"
    case local = "local"
    case listen = "listen"

    func zone(regularWidth: Bool) -> Int {
        switch self {
        case .homeFeed, .article:
            return AdZone.rectangle
        case .homeTop, .sports, .local, .listen:
            return regularWidth ? AdZone.leaderboard : AdZone.mobileBanner
        }
    }
}

struct AdCreative: Equatable {
    let imageURL: URL
    let clickURL: URL
    let beaconURL: URL?
    let altText: String
    let width: CGFloat
    let height: CGFloat
}

enum AdService {

    private static let endpoint = "https://adserver.radiosalina.com/mm-adsrv/www/delivery/asyncspc.php"
    private static let reviveID = "617ad54ec7b76eee24d2cc5f6121ca87"

    /// One banner for a zone, or nil when the zone has nothing to show.
    static func fetch(zone: Int, placement: AdPlacement) async -> AdCreative? {
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "zones", value: String(zone)),
            URLQueryItem(name: "prefix", value: "revive-0-"),
            URLQueryItem(name: "loc", value: "https://www.ksal.com/app/ios/\(placement.rawValue)"),
            URLQueryItem(name: "id", value: reviveID),
        ]
        guard let url = components.url,
              let response = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: response.0) as? [String: Any],
              let entry = json.values.first as? [String: Any],
              let html = entry["html"] as? String
        else { return nil }

        let width = number(entry["width"])
        let height = number(entry["height"])
        guard width > 0, height > 0,
              let click = firstMatch(#"<a[^>]+href='([^']+)'"#, in: html).flatMap(makeURL),
              let image = firstMatch(#"<img[^>]+src='([^']+)'"#, in: html).flatMap(makeURL)
        else { return nil }

        let beacon = firstMatch(#"src='([^']*lg\.php[^']*)'"#, in: html).flatMap(makeURL)
        let alt = firstMatch(#"alt='([^']*)'"#, in: html)?.htmlEntitiesDecoded ?? ""

        return AdCreative(imageURL: image, clickURL: click, beaconURL: beacon, altText: alt, width: width, height: height)
    }

    /// Counts the impression. Call once, when the ad is on screen.
    static func sendBeacon(_ url: URL) {
        URLSession.shared.dataTask(with: url).resume()
    }

    private static func number(_ value: Any?) -> CGFloat {
        if let string = value as? String, let double = Double(string) { return CGFloat(double) }
        if let double = value as? Double { return CGFloat(double) }
        if let int = value as? Int { return CGFloat(int) }
        return 0
    }

    private static func makeURL(_ raw: String) -> URL? {
        URL(string: raw.replacingOccurrences(of: "\\/", with: "/").replacingOccurrences(of: "&amp;", with: "&"))
    }

    private static func firstMatch(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text)
        else { return nil }
        return String(text[range])
    }
}

/// A labelled sponsor slot. Takes no space when the zone has no ad.
struct AdSlot: View {

    let placement: AdPlacement

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var creative: AdCreative?
    @State private var countedImpression = false
    @State private var webPage: InAppWebPage?

    private var zone: Int {
        placement.zone(regularWidth: horizontalSizeClass == .regular)
    }

    var body: some View {
        Group {
            if let creative {
                VStack(spacing: 4) {
                    Text("Advertisement")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Button {
                        webPage = InAppWebPage(url: creative.clickURL)
                    } label: {
                        KFImage(creative.imageURL)
                            .resizable()
                            .aspectRatio(creative.width / creative.height, contentMode: .fit)
                            .frame(maxWidth: creative.width)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(creative.altText.isEmpty ? "Advertisement" : "Advertisement: \(creative.altText)")
                    .accessibilityHint("Opens the advertiser's website")
                }
                .frame(maxWidth: .infinity)
                .onAppear {
                    guard !countedImpression, let beacon = creative.beaconURL else { return }
                    countedImpression = true
                    AdService.sendBeacon(beacon)
                }
            }
        }
        .task(id: zone) {
            countedImpression = false
            creative = await AdService.fetch(zone: zone, placement: placement)
        }
        .webPageSheet($webPage)
    }
}
