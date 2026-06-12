import AppKit

/// 折りたたみ可能な「その他のモード」セクション
///
/// シェブロン付きヘッダー + ModeGridView を内包する。
public final class OtherModesSection: NSView {

    // MARK: - Callback

    public var onModeSelected: ((DisplayMode) -> Void)?

    // MARK: - State

    private var isExpanded: Bool = true {
        didSet { updateExpandedState() }
    }

    // MARK: - Subviews

    private let chevronButton = NSButton()
    private let headerLabel = NSTextField(labelWithString: "")
    private let modeGrid = ModeGridView(frame: .zero)

    // MARK: - Init

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("XIB 非対応") }

    // MARK: - Setup

    private func setupViews() {
        let vStack = NSStackView()
        vStack.orientation = .vertical
        vStack.alignment = .width
        vStack.spacing = DesignTokens.Spacing.itemGap
        vStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(vStack)

        // ヘッダー行: シェブロン + ラベル
        let headerRow = NSStackView()
        headerRow.orientation = .horizontal
        headerRow.alignment = .centerY
        headerRow.spacing = 4

        chevronButton.bezelStyle = .disclosure
        chevronButton.title = ""
        chevronButton.state = .on
        chevronButton.setButtonType(.onOff)
        chevronButton.target = self
        chevronButton.action = #selector(toggleExpanded(_:))
        chevronButton.setContentHuggingPriority(.required, for: .horizontal)
        headerRow.addArrangedSubview(chevronButton)

        headerLabel.stringValue = "その他のモード"
        headerLabel.font = DesignTokens.Typography.sectionHeader
        headerLabel.textColor = DesignTokens.Colors.sectionHeader
        headerLabel.isSelectable = false
        headerRow.addArrangedSubview(headerLabel)

        vStack.addArrangedSubview(headerRow)

        // ModeGridView
        modeGrid.onModeSelected = { [weak self] mode in
            self?.onModeSelected?(mode)
        }
        vStack.addArrangedSubview(modeGrid)

        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: topAnchor),
            vStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            vStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            vStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // MARK: - Public API

    /// グリッドを再構築する
    public func rebuild(
        groups: [(label: String, modes: [DisplayMode])],
        selectedRes: (width: Int, height: Int),
        hiDPIOnly: Bool
    ) {
        // Other Modes では recommendedMode を nil にして全グループをそのまま表示
        modeGrid.rebuild(groups: groups, recommendedMode: nil,
                         selectedRes: selectedRes, hiDPIOnly: hiDPIOnly)
    }

    // MARK: - Actions

    @objc private func toggleExpanded(_ sender: NSButton) {
        isExpanded = sender.state == .on
    }

    private func updateExpandedState() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.allowsImplicitAnimation = true
            modeGrid.isHidden = !isExpanded
        }
        chevronButton.state = isExpanded ? .on : .off
    }
}
