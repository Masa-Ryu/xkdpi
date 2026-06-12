import AppKit

// MARK: - HzBadge

/// リフレッシュレートをピル形状のバッジとして表示するラベル
final class HzBadge: NSTextField {
    init(text: String) {
        super.init(frame: .zero)
        stringValue = text
        isEditable = false
        isSelectable = false
        isBezeled = false
        drawsBackground = false
        font = DesignTokens.Typography.badge
        textColor = DesignTokens.Colors.hzBadgeText
        alignment = .center
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) { fatalError("XIB 非対応") }

    override var intrinsicContentSize: NSSize {
        var s = super.intrinsicContentSize
        s.width += 10
        s.height = max(s.height, 16)
        return s
    }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(
            roundedRect: bounds,
            xRadius: bounds.height / 2,
            yRadius: bounds.height / 2
        )
        DesignTokens.Colors.hzBadgeBackground.setFill()
        path.fill()
        super.draw(dirtyRect)
    }
}

// MARK: - RecommendedBadge

/// 「Recommended」をピル形状のバッジとして表示するラベル
private final class RecommendedBadge: NSTextField {
    init() {
        super.init(frame: .zero)
        stringValue = "Recommended"
        isEditable = false
        isSelectable = false
        isBezeled = false
        drawsBackground = false
        font = .systemFont(ofSize: 10, weight: .semibold)
        textColor = .white
        alignment = .center
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) { fatalError("XIB 非対応") }

    override var intrinsicContentSize: NSSize {
        var s = super.intrinsicContentSize
        s.width += 12
        s.height = max(s.height, 18)
        return s
    }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(
            roundedRect: bounds,
            xRadius: bounds.height / 2,
            yRadius: bounds.height / 2
        )
        DesignTokens.Colors.recommendedBadge.setFill()
        path.fill()
        super.draw(dirtyRect)
    }
}

// MARK: - ModeCardView

/// 解像度モードをカード形式で表示するビュー
///
/// クリックで選択、ホバーで背景変化、おすすめバッジ表示に対応。
public final class ModeCardView: NSView {

    // MARK: - Properties

    public var onSelected: () -> Void = {}

    private let resolutionLabel = NSTextField(labelWithString: "")
    private let ratesStack = NSStackView()
    private var recommendedBadge: NSTextField?
    private var trackingArea: NSTrackingArea?

    private(set) var isCardSelected: Bool = false {
        didSet { needsDisplay = true }
    }
    private var isHovered: Bool = false {
        didSet { needsDisplay = true }
    }

    private let isRecommended: Bool

    // MARK: - Init

    public init(label: String, modes: [DisplayMode], isRecommended: Bool = false) {
        self.isRecommended = isRecommended
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = DesignTokens.Layout.cardCornerRadius
        layer?.borderWidth = 1
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setupViews(label: label, modes: modes)
    }

    required init?(coder: NSCoder) { fatalError("XIB 非対応") }

    // MARK: - Public

    public func setSelected(_ selected: Bool) {
        isCardSelected = selected
    }

    // MARK: - Setup

    private func setupViews(label: String, modes: [DisplayMode]) {
        let vStack = NSStackView()
        vStack.orientation = .vertical
        vStack.alignment = .width
        vStack.spacing = 2
        vStack.edgeInsets = NSEdgeInsets(top: 10, left: DesignTokens.Spacing.cardPadding,
                                       bottom: 10, right: DesignTokens.Spacing.cardPadding)
        vStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(vStack)

        // ヘッダー行（解像度ラベル + おすすめバッジを横並び）
        let headerStack = NSStackView()
        headerStack.orientation = .horizontal
        headerStack.alignment = .centerY
        headerStack.spacing = 6

        resolutionLabel.stringValue = label
        resolutionLabel.font = DesignTokens.Typography.cardResolution
        resolutionLabel.isSelectable = false
        resolutionLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        headerStack.addArrangedSubview(resolutionLabel)

        if isRecommended {
            let badge = RecommendedBadge()
            headerStack.addArrangedSubview(badge)
            recommendedBadge = badge
        }

        vStack.addArrangedSubview(headerStack)

        // リフレッシュレート行
        ratesStack.orientation = .horizontal
        ratesStack.alignment = .centerY
        ratesStack.spacing = 4
        vStack.addArrangedSubview(ratesStack)

        let rates = modes.map { $0.refreshRate }.sorted(by: >)
        for rate in rates {
            ratesStack.addArrangedSubview(HzBadge(text: "\(String(format: "%g", rate))Hz"))
        }

        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: topAnchor),
            vStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            vStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            vStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // MARK: - Drawing

    override public var wantsUpdateLayer: Bool { true }

    override public func updateLayer() {
        if isCardSelected {
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.15).cgColor
            layer?.borderColor = NSColor.controlAccentColor.cgColor
            layer?.borderWidth = 2
        } else if isHovered {
            layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.5).cgColor
            layer?.borderColor = DesignTokens.Colors.cardBorder.cgColor
            layer?.borderWidth = 1
        } else {
            layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
            layer?.borderColor = DesignTokens.Colors.cardBorder.cgColor
            layer?.borderWidth = 1
        }
    }

    // MARK: - Mouse Tracking

    override public func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    override public func mouseEntered(with event: NSEvent) {
        isHovered = true
    }

    override public func mouseExited(with event: NSEvent) {
        isHovered = false
    }

    override public func mouseDown(with event: NSEvent) {
        onSelected()
    }
}
