import Foundation

/// A paged list of ksal.com stories for one category or one search.
@MainActor
@Observable
final class NewsFeed {

    private(set) var articles: [NewsArticle] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var canLoadMore = true

    var category: KSAL.Category
    var searchQuery: String?

    @ObservationIgnored private var nextPage = 1
    @ObservationIgnored private var totalPages: Int?
    @ObservationIgnored private var generation = 0

    private let pageSize = 20

    init(category: KSAL.Category = KSAL.topStories, searchQuery: String? = nil) {
        self.category = category
        self.searchQuery = searchQuery
    }

    /// Loads page 1 again. Keeps the old list visible until the new one arrives.
    func reload() async {
        generation += 1
        nextPage = 1
        totalPages = nil
        canLoadMore = true
        await loadPage(replacing: true)
    }

    /// Loads the first page only if nothing is loaded yet.
    func loadIfNeeded() async {
        if articles.isEmpty && !isLoading {
            await reload()
        }
    }

    /// Call when the last row appears.
    func loadMore() async {
        guard canLoadMore, !isLoading else { return }
        await loadPage(replacing: false)
    }

    private func loadPage(replacing: Bool) async {
        let myGeneration = generation
        isLoading = true
        errorMessage = nil
        defer { if myGeneration == generation { isLoading = false } }

        var components = URLComponents(url: KSAL.postsAPI, resolvingAgainstBaseURL: false)!
        var items = [
            URLQueryItem(name: "per_page", value: String(pageSize)),
            URLQueryItem(name: "page", value: String(nextPage)),
            URLQueryItem(name: "_embed", value: "author,wp:featuredmedia,wp:term"),
        ]
        if let id = category.wordpressID {
            items.append(URLQueryItem(name: "categories", value: String(id)))
        }
        if let searchQuery, !searchQuery.isEmpty {
            items.append(URLQueryItem(name: "search", value: searchQuery))
        }
        components.queryItems = items

        do {
            let (data, response) = try await URLSession.shared.data(from: components.url!)
            guard myGeneration == generation else { return }
            let http = response as? HTTPURLResponse
            if let pages = http?.value(forHTTPHeaderField: "X-WP-TotalPages").flatMap(Int.init) {
                totalPages = pages
            }
            // WordPress answers 400 for a page past the end.
            if http?.statusCode == 400 {
                canLoadMore = false
                return
            }
            let posts = try JSONDecoder().decode([WPPost].self, from: data)
            let new = posts.map(\.article)
            if replacing {
                articles = new
            } else {
                let known = Set(articles.map(\.id))
                articles += new.filter { !known.contains($0.id) }
            }
            nextPage += 1
            if new.isEmpty || (totalPages.map { nextPage > $0 } ?? false) {
                canLoadMore = false
            }
        } catch {
            guard myGeneration == generation else { return }
            if (error as? URLError)?.code == .cancelled { return }
            errorMessage = error.localizedDescription
        }
    }
}
