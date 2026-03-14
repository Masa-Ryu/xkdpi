import AppKit

// MARK: - HzBadge

/// リフレッシュレートをピル形状のバッジとして表示するラベル
private final class HzBadge: NSTextField {
    init(text: String) {
        super.init(frame: .zero)
        stringValue = text
        isEditable = false
        isSelectable = false
        isBezeled = false
        drawsBackground = false
        font = .monospacedDigitSystemFont(ofSize: 10, weight: .semibold)
        textColor = .white
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
        NSColor.controlAccentColor.withAlphaComponent(0.85).setFill()
        path.fill()
        super.draw(dirtyRect)
    }
}

// MARK: - DisplaySectionView

/// ディスプレイ1台分の情報を表示するビュー
///
/// フィルター（HiDPI + リフレッシュレート）で表示する解像度を絞り込む。
/// 解像度ラジオボタンをクリックすると即時適用（最高レートのモードを選択）。
public final class DisplaySectionView: NSView {

    // MARK: - Properties

    private var display: Display
    private var onModeSelected: (DisplayMode) -> Void

    /// HiDPI モードのみ表示するフィルター（デフォルト ON）
    private var hiDPIFilterEnabled: Bool = true
    /// 表示するリフレッシュレートのフィルター（デフォルト: 全レート）
    private var selectedRates: Set<Double>
    /// 全ユニークレートを降順で管理（チェックボックスのタグインデックスに使用）
    private var availableRates: [Double] = []

    /// 現在選択中の解像度（幅×高さ）
    private var selectedRes: (width: Int, height: Int)

    private let resStack = NSStackView()
    private let rateStack = NSStackView()
    /// 「現在: ...」ラベル（モード切替後にテキストのみ更新するため保持）
    private let currentModeLabel = NSTextField(labelWithString: "")

    // MARK: - Coordinate System
    public override var isFlipped: Bool { return true }

    // MARK: - Init

    public init(display: Display, onModeSelected: @escaping (DisplayMode) -> Void) {
        self.display = display
        self.onModeSelected = onModeSelected
        self.selectedRes = (display.currentMode.width, display.currentMode.height)
        self.selectedRates = Set(display.availableModes.map { $0.refreshRate })
        super.init(frame: .zero)
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError("XIB 非対応") }

    // MARK: - Public API

    /// モード切替後に呼び出す。フィルター状態は保持したまま「現在:」表示と選択状態だけ更新する。
    public func updateCurrentMode(to mode: DisplayMode) {
        display.currentMode = mode
        currentModeLabel.stringValue = "現在: \(mode.displayString)"
        selectedRes = (mode.width, mode.height)
        rebuildResolutionButtons()
    }

    // MARK: - Active groups（HiDPI + レート両フィルター適用済み）

    private func activeGroups() -> [(label: String, modes: [DisplayMode])] {
        display.filteredModeGroups(hiDPIOnly: hiDPIFilterEnabled, rates: selectedRates)
    }

    // MARK: - UI Construction

    private func buildUI() {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 8
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        // ① ディスプレイ名 + 種別バッジ（内蔵 / 外部）
        let nameRow = NSStackView()
        nameRow.orientation = .horizontal
        nameRow.alignment = .centerY
        nameRow.spacing = 8
        let nameLabel = makeLabel(display.name, bold: true, size: 14)
        let typeLabel = makeLabel(display.builtin ? "内蔵" : "外部", bold: false, size: 11)
        typeLabel.textColor = display.builtin ? .systemBlue : .secondaryLabelColor
        nameRow.addArrangedSubview(nameLabel)
        nameRow.addArrangedSubview(typeLabel)
        container.addArrangedSubview(nameRow)

        // ② 現在のモード
        currentModeLabel.stringValue = "現在: \(display.currentMode.displayString)"
        currentModeLabel.font = .systemFont(ofSize: 12)
        currentModeLabel.textColor = .secondaryLabelColor
        currentModeLabel.isSelectable = false
        container.addArrangedSubview(currentModeLabel)

        // セパレーター
        let sep = NSBox()
        sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(sep)
        sep.widthAnchor.constraint(equalTo: container.widthAnchor).isActive = true

        // ③ HiDPI フィルター チェックボックス
        let filterCheck = NSButton(checkboxWithTitle: "HiDPI モードのみ表示",
                                   target: self, action: #selector(hiDPIFilterToggled(_:)))
        filterCheck.state = .on
        container.addArrangedSubview(filterCheck)

        // ④ リフレッシュレート フィルター チェックボックス群
        container.addArrangedSubview(makeSectionLabel("リフレッシュレート"))
        rateStack.orientation = .vertical
        rateStack.alignment = .leading
        rateStack.spacing = 4
        container.addArrangedSubview(rateStack)
        buildRateCheckboxes()

        // ⑤ 解像度 ラジオボタン
        resStack.orientation = .vertical
        resStack.alignment = .leading
        resStack.spacing = 4
        container.addArrangedSubview(resStack)

        rebuildResolutionButtons()
    }

    // MARK: - レートチェックボックス構築

    private func buildRateCheckboxes() {
        rateStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        availableRates = Array(Set(display.availableModes.map { $0.refreshRate })).sorted(by: >)
        for (i, rate) in availableRates.enumerated() {
            let btn = NSButton(checkboxWithTitle: "\(String(format: "%g", rate))Hz",
                               target: self, action: #selector(rateToggled(_:)))
            btn.tag = i
            btn.state = selectedRates.contains(rate) ? .on : .off
            rateStack.addArrangedSubview(btn)
        }
    }

    // MARK: - Resolution ボタン再構築

    private func rebuildResolutionButtons() {
        let groups = activeGroups()
        let recommended = display.recommendedMode

        let keyExists = groups.contains {
            $0.modes.first.map { $0.width == selectedRes.width && $0.height == selectedRes.height } ?? false
        }
        if !keyExists, let first = groups.first?.modes.first {
            selectedRes = (first.width, first.height)
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0
            resStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

            if groups.isEmpty {
                resStack.addArrangedSubview(makeLabel("利用可能なモードがありません", bold: false, size: 12))
                return
            }

            // 推奨ラベル（filteredModeGroups のラベル形式に合わせる）
            let recommendedLabel: String? = recommended.map { rec in
                hiDPIFilterEnabled
                    ? "\(rec.width)\u{00D7}\(rec.height)"
                    : rec.resolutionString
            }

            // Recommended セクション
            if let rec = recommended,
               let recLabel = recommendedLabel,
               let recGroup = groups.first(where: { $0.label == recLabel }) {
                resStack.addArrangedSubview(makeSectionLabel("Recommended"))
                let isSelected = rec.width == selectedRes.width && rec.height == selectedRes.height
                let row = makeResolutionRow(
                    radioTitle: "⭐ \(recLabel)",
                    modes: recGroup.modes,
                    isSelected: isSelected,
                    action: #selector(recommendedButtonTapped(_:))
                )
                resStack.addArrangedSubview(row)
            }

            // Other Modes セクション
            let otherGroups = groups.filter { $0.label != recommendedLabel }
            if !otherGroups.isEmpty {
                resStack.addArrangedSubview(makeSectionLabel("Other Modes"))
                for group in otherGroups {
                    let isSelected = group.modes.first.map {
                        $0.width == selectedRes.width && $0.height == selectedRes.height
                    } ?? false
                    let row = makeResolutionRow(
                        radioTitle: group.label,
                        modes: group.modes,
                        isSelected: isSelected,
                        action: #selector(resolutionButtonTapped(_:))
                    )
                    resStack.addArrangedSubview(row)
                }
            }
        }
    }

    // MARK: - Actions

    @objc private func hiDPIFilterToggled(_ sender: NSButton) {
        hiDPIFilterEnabled = (sender.state == .on)
        rebuildResolutionButtons()
    }

    @objc private func rateToggled(_ sender: NSButton) {
        let rate = availableRates[sender.tag]
        if sender.state == .on {
            selectedRates.insert(rate)
        } else {
            selectedRates.remove(rate)
        }
        rebuildResolutionButtons()
    }

    @objc private func recommendedButtonTapped(_ sender: NSButton) {
        // "⭐ " (star + space = 2 chars) を除去してラベルを復元
        let label = String(sender.title.dropFirst(2))
        if let group = activeGroups().first(where: { $0.label == label }),
           let mode = group.modes.max(by: { $0.refreshRate < $1.refreshRate }) {
            selectedRes = (mode.width, mode.height)
            onModeSelected(mode)
        }
    }

    @objc private func resolutionButtonTapped(_ sender: NSButton) {
        // 選択中のグループの最高レートモード（modes は rate 降順）を即時適用
        if let group = activeGroups().first(where: { $0.label == sender.title }),
           let mode = group.modes.first {
            selectedRes = (mode.width, mode.height)
            onModeSelected(mode)
        }
    }

    // MARK: - Helpers

    private func makeLabel(_ text: String, bold: Bool, size: CGFloat) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        label.isSelectable = false
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }

    private func makeSectionLabel(_ text: String) -> NSTextField {
        let label = makeLabel(text, bold: true, size: 12)
        label.textColor = .secondaryLabelColor
        return label
    }

    /// ピル形状の Hz バッジを生成する
    private func makeHzBadge(_ text: String) -> HzBadge {
        HzBadge(text: text)
    }

    /// ラジオボタン + Hz バッジの横並び行を生成する
    private func makeResolutionRow(
        radioTitle: String,
        modes: [DisplayMode],
        isSelected: Bool,
        action: Selector
    ) -> NSStackView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 6
        row.translatesAutoresizingMaskIntoConstraints = false

        let btn = NSButton(radioButtonWithTitle: radioTitle, target: self, action: action)
        btn.state = isSelected ? .on : .off
        row.addArrangedSubview(btn)

        // リフレッシュレートを降順でバッジ表示
        let rates = modes.map { $0.refreshRate }.sorted(by: >)
        for rate in rates {
            row.addArrangedSubview(makeHzBadge("\(String(format: "%g", rate))Hz"))
        }

        return row
    }
}
