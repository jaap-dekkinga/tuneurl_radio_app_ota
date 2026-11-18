import SwiftUI

/// Home tab: KSAL header, weather strip, category chips, lead story and the latest list.
struct HomeScreen: View {

    var openLocal: () -> Void = {}

    @State private var category = KSAL.topStories
    @State private var feeds: [String: NewsFeed] = [:]

    @State private var searchText = ""
    @State private var searchFeed: NewsFeed?

    @State private var showSettings = false

    private var feed: NewsFeed {
        if let existing = feeds[category.id] { return existing }
        return NewsFeed(category: category)
    }

    var body: some View {
        ScrollView {
            if let searchFeed {
                SearchResults(feed: searchFeed)
            } else {
                FeedContent(feed: feed)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .refreshable {
            if let searchFeed {
                await searchFeed.reload()
            } else {
                await feed.reload()
                await WeatherStore.shared.refresh()
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // The wordmark replaces the centred title; "Home" stays as the back-button label.
            ToolbarItem(placement: .principal) {
                Wordmark()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "person.crop.circle")
                }
                .accessibilityLabel("Profile and settings")
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search KSAL news")
        .onSubmit(of: .search) {
            let query = searchText.trimmingCharacters(in: .whitespaces)
            guard !query.isEmpty else { return }
            let results = NewsFeed(category: KSAL.topStories, searchQuery: query)
            searchFeed = results
            Task { await results.reload() }
        }
        .onChange(of: searchText) { _, newValue in
            if newValue.isEmpty { searchFeed = nil }
        }
        .task(id: category) {
            let current = feeds[category.id] ?? NewsFeed(category: category)
            feeds[category.id] = current
            await current.loadIfNeeded()
        }
        .navigationDestination(for: NewsArticle.self) { article in
            ArticleScreen(article: article)
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsScreen()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showSettings = false }
                        }
                    }
            }
            .withEnv()
        }
    }

    @ViewBuilder
    private func FeedContent(feed: NewsFeed) -> some View {
        LazyVStack(alignment: .leading, spacing: 14) {
            WeatherStrip(action: openLocal)
                .padding(.horizontal)

            CategoryChips(categories: KSAL.homeCategories, selection: $category)

            if let lead = feed.articles.first {
                NavigationLink(value: lead) {
                    HeroArticleCard(article: lead)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }

            if feed.articles.count > 1 {
                SectionHeader(title: "Latest")
                    .padding(.horizontal)
                    .padding(.top, 4)

                ArticleList(articles: Array(feed.articles.dropFirst())) {
                    Task { await feed.loadMore() }
                }
                .padding(.horizontal)
            }

            FeedFooter(feed: feed)
        }
        .padding(.top, 8)
        .padding(.bottom, 24)
    }

    @ViewBuilder
    private func SearchResults(feed: NewsFeed) -> some View {
        LazyVStack(alignment: .leading, spacing: 14) {
            if feed.articles.isEmpty && !feed.isLoading && feed.errorMessage == nil {
                ContentUnavailableView.search(text: feed.searchQuery ?? "")
            } else {
                ArticleList(articles: feed.articles) {
                    Task { await feed.loadMore() }
                }
                .padding(.horizontal)
            }
            FeedFooter(feed: feed)
        }
        .padding(.vertical, 8)
    }
}

/// Text stand-in for the KSAL logo. Swap for the real logo asset when the station supplies it.
struct Wordmark: View {
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text("KSAL")
                .font(.system(size: 26, weight: .heavy).italic())
                .foregroundStyle(Color.accentColor)
            Text(".com")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)
        }
        .fixedSize()
        .accessibilityLabel("KSAL")
    }
}

#Preview {
    NavigationStack {
        HomeScreen()
    }
    .withPreviewEnv()
}
