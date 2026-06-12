import AppKit

/// ModeCardView を単一カラムで並べるコンテナ
///
/// おすすめモードを先頭に配置し、残りは解像度降順で表示する。
/// フィルター条件で空になった場合は空状態メッセージを表示する。
public final class ModeGridView: NSView {

    // MARK: - Callback

    public var onModeSelected: ((DisplayMode) -> Void)?

    // MARK: - State

    private let vStack = NSStackView()
    private var cardViews: [ModeCardView] = []

    // MARK: - Init

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("XIB 非対応") }

    // MARK: - Setup

    private func setupViews() {
        vStack.orientation = .vertical
        vStack.alignment = .width
        vStack.spacing = DesignTokens.Spacing.itemGap
        vStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(vStack)

        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: topAnchor),
            vStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            vStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            vStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // MARK: - Public API

    /// グリッドを再構築する
    ///
    /// - Parameters:
    ///   - groups: フィルター適用済みの (label, modes) グループ配列
    ///   - recommendedMode: おすすめモード（該当グループを先頭に配置）
    ///   - selectedRes: 現在選択中の解像度 (width, height)
    ///   - hiDPIOnly: HiDPI フィルター状態（おすすめラベル照合用）
    public func rebuild(
        groups: [(label: String, modes: [DisplayMode])],
        recommendedMode: DisplayMode?,
        selectedRes: (width: Int, height: Int),
        hiDPIOnly: Bool
    ) {
        vStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        cardViews.removeAll()

        if groups.isEmpty {
            let emptyLabel = NSTextField(labelWithString: "フィルター条件に一致するモードがありません")
            emptyLabel.font = .systemFont(ofSize: 12)
            emptyLabel.textColor = .secondaryLabelColor
            emptyLabel.isSelectable = false
            emptyLabel.alignment = .center
            vStack.addArrangedSubview(emptyLabel)
            return
        }

        // おすすめラベルを特定
        let recommendedLabel: String? = recommendedMode.map { rec in
            hiDPIOnly
                ? "\(rec.width)\u{00D7}\(rec.height)"
                : rec.resolutionString
        }

        // おすすめカードを先頭に
        if let recLabel = recommendedLabel,
           let recGroup = groups.first(where: { $0.label == recLabel }) {
            let card = makeCard(
                label: recLabel, modes: recGroup.modes,
                isRecommended: true, selectedRes: selectedRes
            )
            vStack.addArrangedSubview(card)
        }

        // その他のカード
        let otherGroups = groups.filter { $0.label != recommendedLabel }
        for group in otherGroups {
            let card = makeCard(
                label: group.label, modes: group.modes,
                isRecommended: false, selectedRes: selectedRes
            )
            vStack.addArrangedSubview(card)
        }
    }

    // MARK: - Helpers

    private func makeCard(
        label: String,
        modes: [DisplayMode],
        isRecommended: Bool,
        selectedRes: (width: Int, height: Int)
    ) -> ModeCardView {
        let card = ModeCardView(label: label, modes: modes, isRecommended: isRecommended)
        let isSelected = modes.first.map {
            $0.width == selectedRes.width && $0.height == selectedRes.height
        } ?? false
        card.setSelected(isSelected)
        card.onSelected = { [weak self] in
            // 最高レートのモードを選択
            if let mode = modes.max(by: { $0.refreshRate < $1.refreshRate }) {
                self?.onModeSelected?(mode)
            }
        }
        cardViews.append(card)
        return card
    }
}
