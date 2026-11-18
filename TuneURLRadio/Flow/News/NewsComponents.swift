import SwiftUI
import Kingfisher

// MARK: - Story views

/// The large lead story: photo with the headline over it.
struct HeroArticleCard: View {
    let article: NewsArticle

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ArticleImage(url: article.imageURL)
                .frame(height: 230)
                .frame(maxWidth: .infinity)
                .clipped()

            VStack(alignment: .leading, spacing: 6) {
                if let category = article.categoryName {
                    Text(category.uppercased())
                        .font(.caption.weight(.bold))
                        .kerning(0.5)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 4))
                }
                Text(article.title)
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                ArticleByline(article: article)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.55))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// A story row: thumbnail, category, headline and age.
struct ArticleRow: View {
    let article: NewsArticle

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ArticleImage(url: article.thumbnailURL)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                if let category = article.categoryName {
                    Text(category.uppercased())
                        .font(.caption.weight(.bold))
                        .kerning(0.4)
                        .foregroundStyle(Color.accentColor)
                }
                Text(article.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                if let date = article.date {
                    Text(date.formatted(.relative(presentation: .named, unitsStyle: .abbreviated)))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

struct ArticleByline: View {
    let article: NewsArticle

    var body: some View {
        let parts = [
            article.author,
            article.date?.formatted(date: .omitted, time: .shortened),
        ].compactMap { $0 }
        Text(parts.joined(separator: " · "))
            .font(.footnote)
    }
}

struct ArticleImage: View {
    let url: URL?

    var body: some View {
        if let url {
            KFImage(url)
                .placeholder { placeholder }
                .resizable()
                .scaledToFill()
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Rectangle()
            .fill(Color(uiColor: .systemGray4))
            .overlay {
                Image(systemName: "newspaper")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
    }
}

/// Rows in a white rounded card, with a separator between them.
struct ArticleList: View {
    let articles: [NewsArticle]
    var onLastAppear: (() -> Void)?

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(articles) { article in
                NavigationLink(value: article) {
                    ArticleRow(article: article)
                }
                .buttonStyle(.plain)
                .onAppear {
                    if article.id == articles.last?.id { onLastAppear?() }
                }
                if article.id != articles.last?.id {
                    Divider().padding(.leading, 96)
                }
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct FeedFooter: View {
    let feed: NewsFeed

    var body: some View {
        Group {
            if feed.isLoading {
                ProgressView().padding()
            } else if let error = feed.errorMessage {
                VStack(spacing: 8) {
                    Text("Could not load stories")
                        .font(.headline)
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        Task { await feed.reload() }
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Chips and section headers

struct CategoryChips: View {
    let categories: [KSAL.Category]
    @Binding var selection: KSAL.Category

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories) { category in
                    let selected = category == selection
                    Button {
                        selection = category
                    } label: {
                        Text(category.title)
                            .font(.subheadline.weight(selected ? .semibold : .medium))
                            .foregroundStyle(selected ? Color.white : Color.primary)
                            .padding(.horizontal, 14)
                            .frame(height: 34)
                            .background(
                                selected ? Color.accentColor : Color(uiColor: .secondarySystemGroupedBackground),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(.horizontal)
        }
    }
}

struct SectionHeader: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.title2.weight(.heavy))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SmallCapsHeader: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Weather strip

/// One-line weather summary for the top of Home.
struct WeatherStrip: View {
    @State private var weather = WeatherStore.shared
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "cloud.sun")
                    .font(.title3)
                    .foregroundStyle(.primary)
                VStack(alignment: .leading, spacing: 1) {
                    if let now = weather.conditions {
                        Text("Salina · \(now.temperature)°\(now.unit) \(now.summary)")
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                    } else {
                        Text("Salina weather")
                            .font(.subheadline.weight(.semibold))
                    }
                    Text("Forecast, radar, roads and closings")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .task { await weather.refreshIfNeeded() }
    }
}

// MARK: - In-app web pages

extension View {
    /// Presents ksal.com and partner pages in Safari View Controller.
    func webPageSheet(_ page: Binding<InAppWebPage?>) -> some View {
        sheet(item: page) { page in
            SafariView(url: page.url)
                .ignoresSafeArea()
        }
    }
}
