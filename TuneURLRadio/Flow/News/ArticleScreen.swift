import SwiftUI
import UIKit

/// A ksal.com story shown natively: headline, byline, photo, body text.
struct ArticleScreen: View {

    let article: NewsArticle

    @Environment(StateManager.self) private var stateManager
    @Environment(StationsStore.self) private var stationsStore

    @AppStorage("article_text_scale") private var textScale: Double = 1.0
    @State private var savedStories = SavedStoriesStore.shared

    private static let scales: [Double] = [0.9, 1.0, 1.15, 1.3]
    /// Body text column on iPad; iPhone is narrower than this anyway.
    private static let textWidth: CGFloat = 720

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var newsStation: Station? {
        stationsStore.stations.first { $0.id == KSAL.newsStationID }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    if let category = article.categoryName {
                        Text(category.uppercased())
                            .font(.caption.weight(.bold))
                            .kerning(0.5)
                            .foregroundStyle(Color.accentColor)
                    }
                    Text(article.title)
                        .font(.largeTitle.weight(.heavy))
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: 2) {
                        if let author = article.author {
                            Text(author)
                                .font(.subheadline.weight(.semibold))
                        }
                        if let date = article.date {
                            Text(date.formatted(date: .long, time: .shortened))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .readableWidth(Self.textWidth)

                if article.imageURL != nil {
                    ArticleImage(url: article.imageURL)
                        .frame(height: horizontalSizeClass == .regular ? 420 : 230)
                        .frame(maxWidth: 860)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: horizontalSizeClass == .regular ? 16 : 0, style: .continuous))
                        .frame(maxWidth: .infinity)
                }

                ArticleBodyText(html: article.contentHTML, scale: textScale)
                    .padding(.horizontal, 20)
                    .readableWidth(Self.textWidth)

                if let station = newsStation {
                    ListenCard(station: station)
                        .padding(.horizontal, 20)
                        .readableWidth(Self.textWidth)
                }

                if let link = article.link {
                    Link(destination: link) {
                        Label("Open on ksal.com", systemImage: "safari")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: Self.textWidth, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 12)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                let isSaved = savedStories.isSaved(article)
                Button {
                    savedStories.toggle(article)
                } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                }
                .accessibilityLabel(isSaved ? "Remove from saved stories" : "Save story")

                Button {
                    cycleTextSize()
                } label: {
                    Text("Aa").font(.body.weight(.semibold))
                }
                .accessibilityLabel("Text size")

                if let link = article.link {
                    ShareLink(item: link, subject: Text(article.title)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share")
                }
            }
        }
    }

    private func cycleTextSize() {
        let index = Self.scales.firstIndex(of: textScale) ?? 1
        textScale = Self.scales[(index + 1) % Self.scales.count]
    }

    @ViewBuilder
    private func ListenCard(station: Station) -> some View {
        let isThisPlaying = stateManager.isPlaying && stateManager.currentStation?.id == station.id
        Button {
            if isThisPlaying {
                stateManager.expandPlayer()
            } else {
                stateManager.switchStation(to: station)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isThisPlaying ? "waveform" : "play.fill")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor, in: Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text("Hear more on \(station.name)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(isThisPlaying ? "Playing now" : "Live now")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Color(uiColor: .secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// The story body. WordPress HTML is converted to attributed text and shown in a
/// non-scrolling UITextView, so links work and the text sits inside the SwiftUI scroll view.
struct ArticleBodyText: UIViewRepresentable {

    let html: String
    let scale: Double

    final class Coordinator {
        var renderedKey: String?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        let key = "\(scale)|\(html.hashValue)"
        guard context.coordinator.renderedKey != key else { return }
        context.coordinator.renderedKey = key
        view.attributedText = Self.render(html, scale: scale)
        view.invalidateIntrinsicContentSize()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite, width > 0 else { return nil }
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(size.height))
    }

    /// Must run on the main thread (the HTML importer requires it).
    static func render(_ html: String, scale: Double) -> NSAttributedString {
        var cleaned = html
        // Drop embeds and images: the importer would load images synchronously.
        for pattern in [
            "<script[\\s\\S]*?</script>",
            "<style[\\s\\S]*?</style>",
            "<iframe[\\s\\S]*?</iframe>",
            "<img[^>]*>",
        ] {
            cleaned = cleaned.replacingOccurrences(of: pattern, with: "", options: [.regularExpression, .caseInsensitive])
        }

        guard
            let data = cleaned.data(using: .utf8),
            let parsed = try? NSMutableAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue,
                ],
                documentAttributes: nil
            )
        else {
            return NSAttributedString(
                string: html.htmlStripped,
                attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .body),
                    .foregroundColor: UIColor.label,
                ]
            )
        }

        let base = UIFont.preferredFont(forTextStyle: .body).pointSize * 1.08 * CGFloat(scale)
        let full = NSRange(location: 0, length: parsed.length)

        // System font at the reading size; keep bold/italic and relative heading sizes.
        parsed.enumerateAttribute(.font, in: full) { value, range, _ in
            let original = value as? UIFont
            let ratio = min(max((original?.pointSize ?? 12) / 12, 1), 1.6)
            let size = base * ratio
            var font = UIFont.systemFont(ofSize: size, weight: ratio > 1.05 ? .bold : .regular)
            let traits = original?.fontDescriptor.symbolicTraits.intersection([.traitBold, .traitItalic]) ?? []
            if !traits.isEmpty, let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
                font = UIFont(descriptor: descriptor, size: size)
            }
            parsed.addAttribute(.font, value: font, range: range)
        }

        parsed.enumerateAttribute(.paragraphStyle, in: full) { value, range, _ in
            let style = ((value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
            style.lineSpacing = 5 * CGFloat(scale)
            style.paragraphSpacing = 14 * CGFloat(scale)
            parsed.addAttribute(.paragraphStyle, value: style, range: range)
        }

        // Follow light/dark mode instead of the importer's black.
        parsed.removeAttribute(.foregroundColor, range: full)
        parsed.addAttribute(.foregroundColor, value: UIColor.label, range: full)
        parsed.removeAttribute(.backgroundColor, range: full)

        while parsed.length > 0, parsed.string.hasSuffix("\n") {
            parsed.deleteCharacters(in: NSRange(location: parsed.length - 1, length: 1))
        }
        return parsed
    }
}
