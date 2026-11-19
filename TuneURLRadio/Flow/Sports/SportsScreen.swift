import SwiftUI

/// Sports tab: followed teams, then News / Scores / Audio.
struct SportsScreen: View {

    enum SportsSection: String, CaseIterable, Identifiable {
        case news = "News"
        case scores = "Scores"
        case audio = "Audio"
        var id: Self { self }
    }

    @State private var section: SportsSection = .news
    @State private var feed = NewsFeed(category: KSAL.sportsNews)
    @State private var webPage: InAppWebPage?
    @State private var editingTeams = false

    /// Comma-separated team ids, in display order.
    @AppStorage("followed_teams") private var followedTeamIDs = KSAL.teams.map(\.id).joined(separator: ",")

    private var followedTeams: [KSAL.Team] {
        let ids = followedTeamIDs.split(separator: ",").map(String.init)
        return KSAL.teams.filter { ids.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                Picker("Section", selection: $section) {
                    ForEach(SportsSection.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                MyTeams()

                switch section {
                case .news:
                    NewsSection()
                case .scores:
                    LinkCard(KSAL.scoreboard, detail: "Area scores, schedules and broadcast results")
                case .audio:
                    VStack(spacing: 10) {
                        LinkCard(KSAL.sportsAudio, detail: "Interviews and game audio")
                        LinkCard(KSAL.pastShows, detail: "Past shows on SoundCloud")
                    }
                }
            }
            .padding()
            .padding(.bottom, 12)
            .readableWidth()
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .refreshable { await feed.reload() }
        .navigationTitle("Sports")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { editingTeams = true }
                    .accessibilityLabel("Edit my teams")
            }
        }
        .task { await feed.loadIfNeeded() }
        .navigationDestination(for: NewsArticle.self) { article in
            ArticleScreen(article: article)
        }
        .webPageSheet($webPage)
        .sheet(isPresented: $editingTeams) {
            TeamPicker(followedTeamIDs: $followedTeamIDs)
        }
    }

    @ViewBuilder
    private func MyTeams() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SmallCapsHeader(title: "My teams")
            if followedTeams.isEmpty {
                Button("Choose teams to follow") { editingTeams = true }
                    .font(.subheadline.weight(.semibold))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(followedTeams) { team in
                            Button {
                                webPage = InAppWebPage(url: team.url)
                            } label: {
                                VStack(spacing: 5) {
                                    Text(team.short)
                                        .font(.subheadline.weight(.heavy))
                                        .foregroundStyle(.primary)
                                        .frame(width: 56, height: 56)
                                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: Circle())
                                    Text(team.name)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(team.name)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func NewsSection() -> some View {
        SmallCapsHeader(title: "Latest")
        if let lead = feed.articles.first {
            NavigationLink(value: lead) {
                HeroArticleCard(article: lead)
            }
            .buttonStyle(.plain)
        }
        if feed.articles.count > 1 {
            ArticleList(articles: Array(feed.articles.dropFirst())) {
                Task { await feed.loadMore() }
            }
        }
        FeedFooter(feed: feed)
    }

    private func LinkCard(_ link: KSAL.Link, detail: LocalizedStringKey) -> some View {
        Button {
            webPage = InAppWebPage(url: link.url)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: link.systemImage)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(link.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct TeamPicker: View {
    @Binding var followedTeamIDs: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(KSAL.teams) { team in
                Toggle(team.name, isOn: binding(for: team))
            }
            .navigationTitle("My Teams")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func binding(for team: KSAL.Team) -> Binding<Bool> {
        Binding {
            followedTeamIDs.split(separator: ",").map(String.init).contains(team.id)
        } set: { isOn in
            var ids = Set(followedTeamIDs.split(separator: ",").map(String.init))
            if isOn { ids.insert(team.id) } else { ids.remove(team.id) }
            followedTeamIDs = KSAL.teams.map(\.id).filter { ids.contains($0) }.joined(separator: ",")
        }
    }
}
