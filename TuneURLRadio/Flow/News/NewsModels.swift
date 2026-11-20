import Foundation

/// One ksal.com story, built from the WordPress REST API.
struct NewsArticle: Identifiable, Hashable, Codable {
    let id: Int
    let title: String
    let excerpt: String
    let contentHTML: String
    let date: Date?
    let author: String?
    let imageURL: URL?
    let thumbnailURL: URL?
    let categoryName: String?
    let link: URL?
}

// MARK: - WordPress JSON

struct WPPost: Decodable {
    let id: Int
    let dateGMT: String?
    let link: URL?
    let title: Rendered
    let excerpt: Rendered?
    let content: Rendered?
    let embedded: Embedded?

    struct Rendered: Decodable {
        let rendered: String
    }

    struct Embedded: Decodable {
        let author: [Author]?
        let featuredMedia: [Media]?
        let terms: [[Term]]?

        enum CodingKeys: String, CodingKey {
            case author
            case featuredMedia = "wp:featuredmedia"
            case terms = "wp:term"
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            author = try? c.decodeIfPresent([Author].self, forKey: .author)
            featuredMedia = try? c.decodeIfPresent([Media].self, forKey: .featuredMedia)
            terms = try? c.decodeIfPresent([[Term]].self, forKey: .terms)
        }
    }

    struct Author: Decodable {
        let name: String?
    }

    struct Media: Decodable {
        let sourceURL: URL?
        let sizes: [String: Size]

        struct Size: Decodable {
            let sourceURL: URL?
            enum CodingKeys: String, CodingKey { case sourceURL = "source_url" }
        }

        enum CodingKeys: String, CodingKey {
            case sourceURL = "source_url"
            case mediaDetails = "media_details"
        }

        enum DetailKeys: String, CodingKey { case sizes }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            sourceURL = try? c.decodeIfPresent(URL.self, forKey: .sourceURL)
            // WordPress sends `sizes` as [] when empty, so decode leniently.
            if let details = try? c.nestedContainer(keyedBy: DetailKeys.self, forKey: .mediaDetails),
               let sizes = try? details.decode([String: Size].self, forKey: .sizes) {
                self.sizes = sizes
            } else {
                self.sizes = [:]
            }
        }
    }

    struct Term: Decodable {
        let id: Int?
        let name: String?
        let taxonomy: String?
    }

    enum CodingKeys: String, CodingKey {
        case id, link, title, excerpt, content
        case dateGMT = "date_gmt"
        case embedded = "_embedded"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        dateGMT = try? c.decodeIfPresent(String.self, forKey: .dateGMT)
        link = try? c.decodeIfPresent(URL.self, forKey: .link)
        title = try c.decode(Rendered.self, forKey: .title)
        excerpt = try? c.decodeIfPresent(Rendered.self, forKey: .excerpt)
        content = try? c.decodeIfPresent(Rendered.self, forKey: .content)
        embedded = try? c.decodeIfPresent(Embedded.self, forKey: .embedded)
    }

    private static let gmtFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f
    }()

    var article: NewsArticle {
        let media = embedded?.featuredMedia?.first
        let thumb = media?.sizes["medium"]?.sourceURL
            ?? media?.sizes["medium_large"]?.sourceURL
            ?? media?.sourceURL
        let large = media?.sizes["large"]?.sourceURL
            ?? media?.sizes["medium_large"]?.sourceURL
            ?? media?.sourceURL
        let category = embedded?.terms?
            .flatMap { $0 }
            .first { $0.taxonomy == "category" }?
            .name

        return NewsArticle(
            id: id,
            title: title.rendered.htmlStripped,
            excerpt: (excerpt?.rendered ?? "").htmlStripped,
            contentHTML: content?.rendered ?? "",
            date: dateGMT.flatMap { Self.gmtFormatter.date(from: $0) },
            author: embedded?.author?.first?.name,
            imageURL: large,
            thumbnailURL: thumb,
            categoryName: category.map { $0.htmlStripped },
            link: link
        )
    }
}

// MARK: - HTML text helpers

extension String {

    /// Removes tags and decodes the HTML entities WordPress uses in titles and excerpts.
    var htmlStripped: String {
        var text = replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        text = text.htmlEntitiesDecoded
        text = text.replacingOccurrences(of: "[ \\t\\n\\r]+", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "[…] ", with: "…")
        text = text.replacingOccurrences(of: " […]", with: "…")
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var htmlEntitiesDecoded: String {
        guard contains("&") else { return self }
        let named: [String: String] = [
            "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": " ",
            "hellip": "…", "ndash": "–", "mdash": "—", "lsquo": "‘", "rsquo": "’",
            "ldquo": "“", "rdquo": "”", "copy": "©", "reg": "®", "deg": "°",
        ]
        var result = ""
        var index = startIndex
        while index < endIndex {
            let char = self[index]
            if char == "&", let semi = self[index...].firstIndex(of: ";"),
               distance(from: index, to: semi) <= 10 {
                let entity = String(self[self.index(after: index)..<semi])
                var decoded: String?
                if entity.hasPrefix("#x") || entity.hasPrefix("#X") {
                    if let code = UInt32(entity.dropFirst(2), radix: 16), let scalar = Unicode.Scalar(code) {
                        decoded = String(Character(scalar))
                    }
                } else if entity.hasPrefix("#") {
                    if let code = UInt32(entity.dropFirst()), let scalar = Unicode.Scalar(code) {
                        decoded = String(Character(scalar))
                    }
                } else {
                    decoded = named[entity]
                }
                if let decoded {
                    result += decoded
                    index = self.index(after: semi)
                    continue
                }
            }
            result.append(char)
            index = self.index(after: index)
        }
        return result
    }
}
