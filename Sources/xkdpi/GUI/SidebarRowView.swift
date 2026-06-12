import AppKit

/// サイドバーの1行: ディスプレイ名・種別・現在モード要約を表示する
final class SidebarRowView: NSTableCellView {

    private let nameLabel = NSTextField(labelWithString: "")
    private let typeLabel = NSTextField(labelWithString: "")
    private let summaryLabel = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("XIB 非対応") }

    // MARK: - Setup

    private func setupViews() {
        let vStack = NSStackView()
        vStack.orientation = .vertical
        vStack.alignment = .leading
        vStack.spacing = 2
        vStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(vStack)

        // 名前行: ディスプレイ名 + 種別ラベル
        let nameRow = NSStackView()
        nameRow.orientation = .horizontal
        nameRow.alignment = .centerY
        nameRow.spacing = 6

        nameLabel.font = .boldSystemFont(ofSize: 13)
        nameLabel.isSelectable = false
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        typeLabel.font = DesignTokens.Typography.auxiliary
        typeLabel.isSelectable = false
        typeLabel.isEditable = false
        typeLabel.isBezeled = false
        typeLabel.drawsBackground = false
        typeLabel.wantsLayer = true
        typeLabel.alignment = .center
        typeLabel.setContentHuggingPriority(.required, for: .horizontal)

        nameRow.addArrangedSubview(nameLabel)
        nameRow.addArrangedSubview(typeLabel)
        vStack.addArrangedSubview(nameRow)

        // 現在モード要約
        summaryLabel.font = .systemFont(ofSize: 12)
        summaryLabel.textColor = .secondaryLabelColor
        summaryLabel.isSelectable = false
        summaryLabel.lineBreakMode = .byTruncatingTail
        summaryLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        vStack.addArrangedSubview(summaryLabel)

        NSLayoutConstraint.activate([
            vStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            vStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            vStack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    // MARK: - Public API

    func configure(with display: Display) {
        nameLabel.stringValue = display.name

        let isBuiltin = display.builtin
        typeLabel.stringValue = isBuiltin ? " 内蔵 " : " 外部 "
        typeLabel.textColor = .white
        typeLabel.layer?.cornerRadius = 3
        typeLabel.layer?.backgroundColor = (isBuiltin
            ? DesignTokens.Colors.typePillBuiltin
            : DesignTokens.Colors.typePillExternal).cgColor

        let mode = display.currentMode
        var summary = "\(mode.width)\u{00D7}\(mode.height)"
        if mode.isHiDPI { summary += " • HiDPI" }
        summary += " • \(mode.refreshRateString)"
        summaryLabel.stringValue = summary
    }
}
