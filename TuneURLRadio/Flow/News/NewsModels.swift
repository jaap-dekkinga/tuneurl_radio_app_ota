import Foundation

struct NewsArticle: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let link: URL?
    let pubDate: Date?
    let categories: [String]
}
