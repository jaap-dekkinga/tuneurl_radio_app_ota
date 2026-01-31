import UIKit

final class HowToViewController: UIViewController {

    // MARK: - Layout constants (HIG-ish)
    private enum UI {
        static let sidePadding: CGFloat = 24
        static let sectionSpacing: CGFloat = 28
        static let smallSpacing: CGFloat = 8
        static let tileSpacing: CGFloat = 16
        static let tileSize: CGFloat = 156
        static let tileCornerRadius: CGFloat = 20
        static let bubbleCornerRadius: CGFloat = 14
        static let bubblePadding: CGFloat = 16
        static let micSize: CGFloat = 64
        static let maxBodyWidth: CGFloat = 300
        static let ctaHeight: CGFloat = 50
    }

    // MARK: - Views
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let tilesRow = UIStackView()
    private let tileLeft = PlaceholderTileView()
    private let tileRight = PlaceholderTileView()

    private let bubbleA = CalloutBubbleView()

    private let dividerLabel = UILabel()

    private let micHighlight = MicHighlightView()
    private let bubbleB = CalloutBubbleView()

    private let ctaButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "How To"

        configureSubviews()
        layoutSubviews()
        applyContent()
    }

    // MARK: - Setup

    private func configureSubviews() {
        // Scroll setup
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true

        // Title
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle).withWeight(.semibold)
        titleLabel.adjustsFontForContentSizeCategory = true

        // Subtitle
        subtitleLabel.textAlignment = .left
        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.adjustsFontForContentSizeCategory = true

        // Tiles row
        tilesRow.axis = .horizontal
        tilesRow.alignment = .center
        tilesRow.distribution = .equalSpacing
        tilesRow.spacing = UI.tileSpacing

        tileLeft.translatesAutoresizingMaskIntoConstraints = false
        tileRight.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tileLeft.widthAnchor.constraint(equalToConstant: UI.tileSize),
            tileLeft.heightAnchor.constraint(equalToConstant: UI.tileSize),
            tileRight.widthAnchor.constraint(equalToConstant: UI.tileSize),
            tileRight.heightAnchor.constraint(equalToConstant: UI.tileSize)
        ])

        // Bubble A
        bubbleA.configure(
            headline: "🎧 Listening on your phone?",
            body: "Tap a station to stream audio directly in the app.",
            helper: "Use this when audio comes from your phone speakers or headphones."
        )

        // Divider
        dividerLabel.numberOfLines = 0
        dividerLabel.textAlignment = .center
        dividerLabel.font = UIFont.preferredFont(forTextStyle: .footnote).withWeight(.medium)
        dividerLabel.textColor = .secondaryLabel
        dividerLabel.adjustsFontForContentSizeCategory = true

        // Bubble B
        bubbleB.configure(
            headline: "📻 Listening to live radio nearby?",
            body: "Tap the microphone to let TuneURL listen along and unlock interactive moments.",
            helper: "Use this when audio comes from a car radio, smart speaker, or broadcast station."
        )

        // CTA
        ctaButton.setTitle("Got it — start listening", for: .normal)
        ctaButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        ctaButton.titleLabel?.adjustsFontForContentSizeCategory = true
        ctaButton.tintColor = .white
        ctaButton.backgroundColor = .systemBlue
        ctaButton.layer.cornerRadius = 12
        ctaButton.addTarget(self, action: #selector(didTapCTA), for: .touchUpInside)
    }

    private func layoutSubviews() {
        [scrollView, ctaButton].forEach { v in
            v.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(v)
        }

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        // Put everything in a vertical stack for simple spacing
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel,
            tilesRow,
            bubbleA,
            dividerLabel,
            micHighlight,
            bubbleB
        ])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = UI.sectionSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false

        tilesRow.addArrangedSubview(tileLeft)
        tilesRow.addArrangedSubview(tileRight)

        contentView.addSubview(stack)

        // Scroll view + fixed CTA at bottom
        NSLayoutConstraint.activate([
            ctaButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UI.sidePadding),
            ctaButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UI.sidePadding),
            ctaButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            ctaButton.heightAnchor.constraint(equalToConstant: UI.ctaHeight),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: ctaButton.topAnchor, constant: -16),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),

            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UI.sidePadding),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UI.sidePadding),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])

        // Make some items fill width while keeping the stack centered
        [titleLabel, subtitleLabel, bubbleA, bubbleB].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: stack.trailingAnchor),

            subtitleLabel.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: stack.trailingAnchor),

            bubbleA.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            bubbleA.trailingAnchor.constraint(equalTo: stack.trailingAnchor),

            bubbleB.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            bubbleB.trailingAnchor.constraint(equalTo: stack.trailingAnchor),

            dividerLabel.widthAnchor.constraint(lessThanOrEqualToConstant: UI.maxBodyWidth)
        ])
    }

    private func applyContent() {
        titleLabel.text = "How TuneURL Works"
        subtitleLabel.text = "Connect with live radio or stream directly from your phone."
        dividerLabel.text = "Your phone becomes a companion device — TuneURL detects what’s playing and brings you interactive content in real time."
    }

    @objc private func didTapCTA() {
        // Typical behavior: jump back to the primary "Stations" tab.
        tabBarController?.selectedIndex = 0
    }
}

// MARK: - Small UI helpers

private final class PlaceholderTileView: UIView {
    private let icon = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemGray5
        layer.cornerRadius = HowToViewController.UI.tileCornerRadius

        // Dashed border
        let dashed = CAShapeLayer()
        dashed.strokeColor = UIColor.systemGray3.cgColor
        dashed.lineDashPattern = [6, 4]
        dashed.fillColor = UIColor.clear.cgColor
        dashed.lineWidth = 1
        layer.addSublayer(dashed)

        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.image = UIImage(systemName: "waveform")
        icon.tintColor = .tertiaryLabel
        icon.contentMode = .scaleAspectFit
        addSubview(icon)

        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 64),
            icon.heightAnchor.constraint(equalToConstant: 64)
        ])

        // Update dashed path on layout
        self.layoutSubviewsCallback = { [weak self, weak dashed] in
            guard let self, let dashed else { return }
            dashed.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius).cgPath
            dashed.frame = self.bounds
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // Simple layout callback hook
    private var layoutSubviewsCallback: (() -> Void)?
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutSubviewsCallback?()
    }
}

private final class CalloutBubbleView: UIView {
    private let headlineLabel = UILabel()
    private let bodyLabel = UILabel()
    private let helperLabel = UILabel()
    private let vStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemGray6
        layer.cornerRadius = HowToViewController.UI.bubbleCornerRadius

        vStack.axis = .vertical
        vStack.spacing = 6
        vStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(vStack)

        headlineLabel.numberOfLines = 0
        headlineLabel.font = UIFont.preferredFont(forTextStyle: .headline).withWeight(.semibold)
        headlineLabel.adjustsFontForContentSizeCategory = true

        bodyLabel.numberOfLines = 0
        bodyLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        bodyLabel.adjustsFontForContentSizeCategory = true

        helperLabel.numberOfLines = 0
        helperLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        helperLabel.textColor = .tertiaryLabel
        helperLabel.adjustsFontForContentSizeCategory = true

        [headlineLabel, bodyLabel, helperLabel].forEach { vStack.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: topAnchor, constant: HowToViewController.UI.bubblePadding),
            vStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -HowToViewController.UI.bubblePadding),
            vStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: HowToViewController.UI.bubblePadding),
            vStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -HowToViewController.UI.bubblePadding)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(headline: String, body: String, helper: String) {
        headlineLabel.text = headline
        bodyLabel.text = body
        helperLabel.text = helper
        bodyLabel.textColor = .secondaryLabel
    }
}

private final class MicHighlightView: UIView {
    private let circle = UIView()
    private let micImage = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false

        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.10)
        circle.layer.cornerRadius = HowToViewController.UI.micSize / 2

        // "Glow"
        circle.layer.shadowColor = UIColor.systemBlue.withAlphaComponent(0.30).cgColor
        circle.layer.shadowOpacity = 1
        circle.layer.shadowRadius = 12
        circle.layer.shadowOffset = .zero

        micImage.translatesAutoresizingMaskIntoConstraints = false
        micImage.image = UIImage(systemName: "mic.fill")
        micImage.tintColor = .systemBlue
        micImage.contentMode = .scaleAspectFit

        addSubview(circle)
        circle.addSubview(micImage)

        NSLayoutConstraint.activate([
            circle.widthAnchor.constraint(equalToConstant: HowToViewController.UI.micSize),
            circle.heightAnchor.constraint(equalToConstant: HowToViewController.UI.micSize),
            circle.centerXAnchor.constraint(equalTo: centerXAnchor),
            circle.centerYAnchor.constraint(equalTo: centerYAnchor),

            micImage.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            micImage.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
            micImage.widthAnchor.constraint(equalToConstant: 28),
            micImage.heightAnchor.constraint(equalToConstant: 28),

            heightAnchor.constraint(equalToConstant: HowToViewController.UI.micSize)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - UIFont convenience
private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
