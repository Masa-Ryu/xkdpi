import AppKit

/// 現在のディスプレイモードをヒーローカード形式で大きく表示するビュー
///
/// NSVisualEffectView 背景の角丸カードにディスプレイ名・解像度・HiDPI/Hz/PPI 情報を配置する。
public final class CurrentModeHeroView: NSView {

    // MARK: - Subviews

    private let background = NSVisualEffectView()
    private let nameLabel = NSTextField(labelWithString: "")
    private let typePill = NSTextField(labelWithString: "")
    private let resLabel = NSTextField(labelWithString: "")
    private let detailStack = NSStackView()

    private var display: Display

    // MARK: - Init

    public init(display: Display) {
        self.display = display
        super.init(frame: .zero)
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setupViews()
        applyDisplay()
    }

    required init?(coder: NSCoder) { fatalError("XIB 非対応") }

    // MARK: - Public API

    public func updateMode(_ mode: DisplayMode) {
        display.currentMode = mode
        applyDisplay()
    }

    // MARK: - Setup

    private func setupViews() {
        // 背景: NSVisualEffectView
        background.material = .underPageBackground
        background.blendingMode = .behindWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = DesignTokens.Layout.heroCornerRadius
        background.layer?.masksToBounds = true
        background.translatesAutoresizingMaskIntoConstraints = false
        addSubview(background)

        // コンテナ vStack
        let vStack = NSStackView()
        vStack.orientation = .vertical
        vStack.alignment = .leading
        vStack.spacing = 4
        vStack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        vStack.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(vStack)

        // 名前行: ディスプレイ名 + 種別ピル
        let nameRow = NSStackView()
        nameRow.orientation = .horizontal
        nameRow.alignment = .centerY
        nameRow.spacing = 8

        nameLabel.font = DesignTokens.Typography.displayName
        nameLabel.isSelectable = false
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        typePill.font = .systemFont(ofSize: 10, weight: .semibold)
        typePill.alignment = .center
        typePill.isSelectable = false
        typePill.isEditable = false
        typePill.isBezeled = false
        typePill.drawsBackground = false
        typePill.wantsLayer = true
        typePill.setContentHuggingPriority(.required, for: .horizontal)

        nameRow.addArrangedSubview(nameLabel)
        nameRow.addArrangedSubview(typePill)
        vStack.addArrangedSubview(nameRow)

        // 解像度ラベル（大きく表示）
        resLabel.font = DesignTokens.Typography.heroResolution
        resLabel.isSelectable = false
        vStack.addArrangedSubview(resLabel)

        // 詳細行: HiDPI バッジ + Hz + PPI
        detailStack.orientation = .horizontal
        detailStack.alignment = .centerY
        detailStack.spacing = 8
        vStack.addArrangedSubview(detailStack)

        // レイアウト制約
        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: topAnchor),
            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor),
            background.bottomAnchor.constraint(equalTo: bottomAnchor),

            vStack.topAnchor.constraint(equalTo: background.topAnchor),
            vStack.leadingAnchor.constraint(equalTo: background.leadingAnchor),
            vStack.trailingAnchor.constraint(equalTo: background.trailingAnchor),
            vStack.bottomAnchor.constraint(equalTo: background.bottomAnchor),
        ])
    }

    // MARK: - Apply

    private func applyDisplay() {
        let mode = display.currentMode

        nameLabel.stringValue = display.name
        typePill.stringValue = display.builtin ? " 内蔵 " : " 外部 "
        typePill.layer?.cornerRadius = 4
        typePill.layer?.backgroundColor = (display.builtin
            ? DesignTokens.Colors.typePillBuiltin
            : DesignTokens.Colors.typePillExternal).cgColor
        typePill.textColor = .white

        resLabel.stringValue = "\(mode.width) \u{00D7} \(mode.height)"

        // 詳細行を再構築
        detailStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if mode.isHiDPI {
            detailStack.addArrangedSubview(makeBadge("HiDPI", color: .systemGreen))
        }
        detailStack.addArrangedSubview(makeDetailLabel(mode.refreshRateString))

        if let ppi = display.ppi {
            detailStack.addArrangedSubview(makeDetailLabel("\(Int(ppi)) PPI"))
        }
    }

    // MARK: - Helpers

    private func makeBadge(_ text: String, color: NSColor) -> NSView {
        let label = NSTextField(labelWithString: " \(text) ")
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .white
        label.alignment = .center
        label.isSelectable = false
        label.wantsLayer = true
        label.layer?.cornerRadius = 4
        label.layer?.backgroundColor = color.withAlphaComponent(0.85).cgColor
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }

    private func makeDetailLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = DesignTokens.Typography.body
        label.textColor = .secondaryLabelColor
        label.isSelectable = false
        return label
    }
}
