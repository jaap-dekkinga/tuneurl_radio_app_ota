import SwiftUI

/// Stories the listener saved from an article, kept on the device (UserDefaults).
@MainActor
@Observable
final class SavedStoriesStore {

    static let shared = SavedStoriesStore()

    private(set) var stories: [NewsArticle] = []

    @ObservationIgnored private let key = "saved_stories_v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([NewsArticle].self, from: data) {
            stories = decoded
        }
    }

    func isSaved(_ article: NewsArticle) -> Bool {
        stories.contains { $0.id == article.id }
    }

    func toggle(_ article: NewsArticle) {
        if isSaved(article) {
            stories.removeAll { $0.id == article.id }
        } else {
            stories.insert(article, at: 0)
        }
        persist()
    }

    func remove(atOffsets offsets: IndexSet) {
        stories.remove(atOffsets: offsets)
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(stories) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

struct SavedStoriesScreen: View {

    @State private var store = SavedStoriesStore.shared

    var body: some View {
        List {
            ForEach(store.stories) { article in
                NavigationLink(value: article) {
                    ArticleRow(article: article)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 12))
            }
            .onDelete { store.remove(atOffsets: $0) }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if store.stories.isEmpty {
                ContentUnavailableView(
                    "No Saved Stories",
                    systemImage: "bookmark",
                    description: Text("Tap the bookmark on a story to read it later.")
                )
            }
        }
        .navigationTitle("Saved Stories")
        .toolbar {
            if !store.stories.isEmpty {
                EditButton()
            }
        }
    }
}
