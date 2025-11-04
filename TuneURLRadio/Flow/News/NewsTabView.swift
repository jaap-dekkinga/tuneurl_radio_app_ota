import SwiftUI

struct NewsTabView: View {
    @StateObject private var viewModel = NewsFeedViewModel()

    // Sorted list of category names from the feed
    private var sortedCategories: [String] {
        viewModel.articlesByCategory.keys.sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
    }

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.articlesByCategory.isEmpty {
                    ProgressView("Loading news…")
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Text("Could not load news")
                            .font(.headline)
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            viewModel.load()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(sortedCategories, id: \.self) { category in
                            if let items = viewModel.articlesByCategory[category],
                               !items.isEmpty {
                                Section(header: Text(category)) {
                                    ForEach(items) { article in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(article.title)
                                                .font(.headline)
                                            if !article.summary.isEmpty {
                                                Text(article.summary)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(3)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                        .onTapGesture {
                                            if let url = article.link {
                                                UIApplication.shared.open(url)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("News")
        }
        .onAppear {
            if viewModel.articlesByCategory.isEmpty {
                viewModel.load()
            }
        }
    }
}
