import SwiftUI

/// Local tab: Salina weather, closings and the ksal.com community pages.
struct LocalScreen: View {

    @State private var weather = WeatherStore.shared
    @State private var webPage: InAppWebPage?

    /// Four tiles across on iPhone, more on iPad.
    private let columns = [GridItem(.adaptive(minimum: 78), spacing: 8)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                WeatherCard()

                SmallCapsHeader(title: "Community")
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(KSAL.communityLinks) { link in
                        Button {
                            webPage = InAppWebPage(url: link.url)
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: link.systemImage)
                                    .font(.title3)
                                    .foregroundStyle(Color.accentColor)
                                Text(link.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                            }
                            .padding(.horizontal, 4)
                            .frame(maxWidth: .infinity, minHeight: 78)
                            .background(Color(uiColor: .secondarySystemGroupedBackground),
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .padding(.bottom, 12)
            .readableWidth()
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .refreshable { await weather.refresh() }
        .navigationTitle("Local")
        .task { await weather.refreshIfNeeded() }
        .webPageSheet($webPage)
    }

    @ViewBuilder
    private func WeatherCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Salina weather")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                    if let now = weather.conditions {
                        Text("\(now.temperature)°\(now.unit)")
                            .font(.system(size: 40, weight: .light))
                        Text(now.summary)
                            .font(.subheadline)
                    } else if weather.isLoading {
                        ProgressView()
                            .padding(.vertical, 8)
                    } else {
                        Text("Weather unavailable")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "cloud.sun")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                ForEach([KSAL.forecast, KSAL.radar, KSAL.roads]) { link in
                    Button {
                        webPage = InAppWebPage(url: link.url)
                    } label: {
                        Text(link.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color(uiColor: .tertiarySystemGroupedBackground),
                                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            Button {
                webPage = InAppWebPage(url: KSAL.closings.url)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: KSAL.closings.systemImage)
                        .foregroundStyle(Color.accentColor)
                    Text("Local closings & delays")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(minHeight: 36)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text("Weather data: National Weather Service")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        LocalScreen()
    }
}
