import AppKit

/// 右ペイン: Hero + おすすめ + Filter + Other Modes を縦に配置する詳細ビュー
public final class DetailPaneView: NSView {

    // MARK: - Callback

    public var onModeSelected: ((DisplayMode) -> Void)?

    // MARK: - State

    private var display: Display
    private var hiDPIOnly: Bool = true
    private var selectedRates: Set<Double>
    private var selectedRes: (width: Int, height: Int)

    // MARK: - Subviews

    private let scrollView = NSScrollView()
    private let contentStack = NSStackView()
    private let heroView: CurrentModeHeroView
    private var recommendedHeader: NSTextField?
    private var recommendedCard: ModeCardView?
    private var recommendedCurrentNote: NSTextField?
    private var filterBar: FilterBarView?
    private let otherModesSection = OtherModesSection(frame: .zero)

    // MARK: - Init

    public init(display: Display) {
        self.display = display
        self.selectedRes = (display.currentMode.width, display.currentMode.height)
        self.selectedRates = Set(display.availableModes.map { $0.refreshRate })
        self.heroView = CurrentModeHeroView(display: display)
        super.init(frame: .zero)
        setupViews()
        rebuildModes()
    }

    required init?(coder: NSCoder) { fatalError("XIB 非対応") }

    // MARK: - Setup

    private func setupViews() {
        // スクロールビュー
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        // コンテンツ用 vStack
        contentStack.orientation = .vertical
        contentStack.alignment = .width
        contentStack.spacing = DesignTokens.Spacing.sectionGap
        contentStack.edgeInsets = NSEdgeInsets(
            top: DesignTokens.Spacing.panePadding,
            left: DesignTokens.Spacing.panePadding,
            bottom: DesignTokens.Spacing.panePadding,
            right: DesignTokens.Spacing.panePadding
        )
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        // Flipped clip view for top-to-bottom layout
        let clipView = FlippedClipView()
        clipView.drawsBackground = false
        scrollView.contentView = clipView
        scrollView.documentView = contentStack

        // 1. Hero
        contentStack.addArrangedSubview(heroView)

        // 2. おすすめセクション（プレースホルダ、rebuildModes で構築）
        // recommendedHeader / recommendedCard は rebuildModes 内で動的に追加

        // 3. フィルターバー
        let rates = Array(Set(display.availableModes.map { $0.refreshRate }))
        let bar = FilterBarView(rates: rates, initialHiDPIOnly: hiDPIOnly, initialSelectedRates: selectedRates)
        bar.onFilterChanged = { [weak self] tuple in
            self?.hiDPIOnly = tuple.0
            self?.selectedRates = tuple.1
            self?.rebuildModes()
        }
        filterBar = bar

        // 4. Other Modes
        otherModesSection.onModeSelected = { [weak self] mode in
            self?.onModeSelected?(mode)
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: clipView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
    }

    // MARK: - Public API

    /// モード切替後に hero + 選択状態を更新する
    public func updateCurrentMode(to mode: DisplayMode) {
        display.currentMode = mode
        selectedRes = (mode.width, mode.height)
        heroView.updateMode(mode)
        rebuildModes()
    }

    // MARK: - Mode Rebuild

    private func rebuildModes() {
        // contentStack をリセットして再構築
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 1. Hero
        contentStack.addArrangedSubview(heroView)

        // 2. おすすめ
        let groups = display.filteredModeGroups(hiDPIOnly: hiDPIOnly, rates: selectedRates)
        let recommended = display.recommendedMode

        // selectedRes がグループに存在しなければ先頭に合わせる
        let keyExists = groups.contains { group in
            group.modes.first.map { $0.width == selectedRes.width && $0.height == selectedRes.height } ?? false
        }
        if !keyExists, let first = groups.first?.modes.first {
            selectedRes = (first.width, first.height)
        }

        let recommendedLabel: String? = recommended.map { rec in
            hiDPIOnly
                ? "\(rec.width)\u{00D7}\(rec.height)"
                : rec.resolutionString
        }

        if let rec = recommended,
           let recLabel = recommendedLabel,
           let recGroup = groups.first(where: { $0.label == recLabel }) {

            let header = NSTextField(labelWithString: "おすすめ")
            header.font = DesignTokens.Typography.sectionHeader
            header.textColor = DesignTokens.Colors.sectionHeader
            header.isSelectable = false
            contentStack.addArrangedSubview(header)

            let card = ModeCardView(label: recLabel, modes: recGroup.modes, isRecommended: true)
            let isSelected = rec.width == selectedRes.width && rec.height == selectedRes.height
            card.setSelected(isSelected)
            card.onSelected = { [weak self] in
                if let mode = recGroup.modes.max(by: { $0.refreshRate < $1.refreshRate }) {
                    self?.onModeSelected?(mode)
                }
            }
            contentStack.addArrangedSubview(card)

            // Current と一致する場合の補足
            if rec.width == display.currentMode.width && rec.height == display.currentMode.height {
                let note = NSTextField(labelWithString: "✓ 現在のモードはおすすめと一致しています")
                note.font = DesignTokens.Typography.auxiliary
                note.textColor = DesignTokens.Colors.auxiliary
                note.isSelectable = false
                contentStack.addArrangedSubview(note)
            }
        }

        // 3. フィルターバー
        if let bar = filterBar {
            contentStack.addArrangedSubview(bar)
        }

        // 4. Other Modes
        let otherGroups = groups.filter { $0.label != recommendedLabel }
        otherModesSection.rebuild(groups: otherGroups, selectedRes: selectedRes, hiDPIOnly: hiDPIOnly)
        contentStack.addArrangedSubview(otherModesSection)
    }
}

// MARK: - FlippedClipView

/// top-aligned スクロールのための flipped ClipView
private final class FlippedClipView: NSClipView {
    override var isFlipped: Bool { true }
}
