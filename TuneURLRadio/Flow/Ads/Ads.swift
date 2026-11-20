import SwiftUI
import Kingfisher

private let log = Log(label: "Ads")

// Sponsor ads from the station's own ad server (Revive Adserver at adserver.radiosalina.com),
// the same server and zones that ksal.com uses. Impressions and clicks are counted by Revive,
// so app traffic shows up in the station's existing reports (look for `loc` = ksal.com/app/ios/…).
//
// Zones on ksal.com at phone size (read 2026-11-19). Home page: 17 top banner, 2 in Farming
// News, 20 and 5 near Latest Auctions, 16 before Sports News (4 and 27 were empty).
// Story pages: 17 top banner, 6 and 24 after the story (25 was empty).
// Ask the station to create app-only zones if they want to sell app ads separately, then
// change the ids below.

enum AdZone {
    static let topBanner = 17        // 728×90, top of every ksal.com page
    static let homeBox = 20          // 300×250, home page
    static let mobileBanner = 5      // 288×100, home page
    static let sportsBanner = 16     // 1110×180, before Sports News on the home page
    static let storyBanner = 6       // 728×90, after the story on story pages
    static let storyBox = 24         // 300×250, after the story on story pages
}

/// Where an ad appears in the app. Each placement uses the zone of the matching spot on
/// ksal.com, so an advertiser who bought a spot on the website also appears in the app.
enum AdPlacement: String {
    case homeTop = "home-top"            // under the weather strip
    case homeFeed = "home-feed"          // after the first five stories
    case articleBanner = "article-banner" // after the story text
    case articleBox = "article-box"      // under the story banner
    case sports = "sports"               // under My teams
    case local = "local"                 // under the weather card
    case listen = "listen"               // under the stations

    func zone(regularWidth: Bool) -> Int {
        switch self {
        case .homeTop: return AdZone.topBanner
        case .homeFeed: return AdZone.homeBox
        case .articleBanner: return AdZone.storyBanner
        case .articleBox: return AdZone.storyBox
        case .sports: return AdZone.sportsBanner
        case .local, .listen: return regularWidth ? AdZone.topBanner : AdZone.mobileBanner
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
        guard let url = components.url else { return nil }

        let data: Data
        do {
            data = try await URLSession.shared.data(from: url).0
        } catch {
            log.write("Ad \(placement.rawValue) (zone \(zone)): request failed: \(error.localizedDescription)", level: .error)
            return nil
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entry = json.values.first as? [String: Any],
              let html = entry["html"] as? String
        else {
            log.write("Ad \(placement.rawValue) (zone \(zone)): no ad from the server")
            return nil
        }

        let width = number(entry["width"])
        let height = number(entry["height"])
        guard width > 0, height > 0,
              let click = firstMatch(#"<a[^>]+href='([^']+)'"#, in: html).flatMap(makeURL),
              let image = firstMatch(#"<img[^>]+src='([^']+)'"#, in: html).flatMap(makeURL)
        else {
            log.write("Ad \(placement.rawValue) (zone \(zone)): could not read the ad (size \(width)x\(height))", level: .error)
            return nil
        }

        let beacon = firstMatch(#"src='([^']*lg\.php[^']*)'"#, in: html).flatMap(makeURL)
        let alt = firstMatch(#"alt='([^']*)'"#, in: html)?.htmlEntitiesDecoded ?? ""

        log.write("Ad \(placement.rawValue) (zone \(zone)): showing \"\(alt)\" \(Int(width))x\(Int(height))")
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
        // A ZStack with a zero-height spacer, not a Group: a Group with nothing in it has no
        // view to attach .task to, so the ad was never requested and the slot stayed empty.
        ZStack {
            Color.clear.frame(height: 0)
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
