import Foundation
import Combine

final class NewsFeedViewModel: NSObject, ObservableObject {
    @Published var articlesByCategory: [String: [NewsArticle]] = [:]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - RSS parsing state

    private var currentElement: String = ""
    private var currentTitle: String = ""
    private var currentDescription: String = ""
    private var currentLink: String = ""
    private var currentPubDate: String = ""

    // We now support multiple <category> tags per item
    private var currentCategories: [String] = []
    private var currentCategoryText: String = ""

    private var currentItems: [NewsArticle] = []
    private var parser: XMLParser?

    private let feedURL = URL(string: "https://www.ksal.com/feed/")!

    // MARK: - Public API

    func load() {
        isLoading = true
        errorMessage = nil
        currentItems = []

        let task = URLSession.shared.dataTask(with: feedURL) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.isLoading = false
                    self.errorMessage = "Failed to load feed: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    self.isLoading = false
                    self.errorMessage = "No data from RSS feed"
                    return
                }

                self.parser = XMLParser(data: data)
                self.parser?.delegate = self
                self.parser?.parse()
            }
        }

        task.resume()
    }
}

// MARK: - XMLParserDelegate

extension NewsFeedViewModel: XMLParserDelegate {
    func parserDidStartDocument(_ parser: XMLParser) {
        currentItems.removeAll()
    }

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName

        if elementName == "item" {
            currentTitle = ""
            currentDescription = ""
            currentLink = ""
            currentPubDate = ""
            currentCategories = []
            currentCategoryText = ""
        } else if elementName == "category" {
            currentCategoryText = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        switch currentElement {
        case "title":
            currentTitle += trimmed + " "
        case "description":
            currentDescription += trimmed + " "
        case "link":
            currentLink += trimmed
        case "pubDate":
            currentPubDate += trimmed + " "
        case "category":
            // Accumulate full text of this <category> element
            currentCategoryText += trimmed + " "
        default:
            break
        }
    }

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {

        if elementName == "category" {
            let cat = currentCategoryText
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !cat.isEmpty {
                currentCategories.append(cat)
            }
            currentCategoryText = ""
        }

        if elementName == "item" {
            let date = parsePubDate(currentPubDate)

            let article = NewsArticle(
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                summary: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                link: URL(string: currentLink),
                pubDate: date,
                categories: currentCategories
            )

            currentItems.append(article)
        }

        currentElement = ""
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        var dict: [String: [NewsArticle]] = [:]

        let fallbackCategory = "Uncategorized"

        for item in currentItems {
            let categories = item.categories.isEmpty ? [fallbackCategory] : item.categories

            for rawCat in categories {
                let cat = rawCat.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !cat.isEmpty else { continue }
                dict[cat, default: []].append(item)
            }
        }

        // Sort articles in each category by date (newest first)
        for (category, items) in dict {
            dict[category] = items.sorted { (a, b) in
                (a.pubDate ?? .distantPast) > (b.pubDate ?? .distantPast)
            }
        }

        articlesByCategory = dict
        isLoading = false
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        isLoading = false
        errorMessage = "Parse error: \(parseError.localizedDescription)"
    }
}

// MARK: - Helpers

private func parsePubDate(_ string: String) -> Date? {
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    // Typical RSS date format: "Mon, 04 Nov 2025 10:30:00 +0000"
    formatter.dateFormat = "E, dd MMM yyyy HH:mm:ss Z"
    return formatter.date(from: trimmed)
}
