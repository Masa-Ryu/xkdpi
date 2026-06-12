import AppKit

/// HiDPI フィルターとリフレッシュレートフィルターを横1行に表示するバー
///
/// セグメントコントロール ("HiDPI" / "すべて") + レートトグルピルで構成。
public final class FilterBarView: NSView {

    // MARK: - Callback

    /// (hiDPIOnly, selectedRates) を返すコールバック
    public var onFilterChanged: ((Bool, Set<Double>)) -> Void = { _ in }

    // MARK: - State

    private var hiDPIOnly: Bool = true
    private var selectedRates: Set<Double>
    private let availableRates: [Double]

    // MARK: - Subviews

    private let segmentControl = NSSegmentedControl()
    private let rateContainer = NSStackView()

    // MARK: - Init

    public init(rates: [Double], initialHiDPIOnly: Bool = true, initialSelectedRates: Set<Double>? = nil) {
        self.availableRates = rates.sorted(by: >)
        self.hiDPIOnly = initialHiDPIOnly
        self.selectedRates = initialSelectedRates ?? Set(rates)
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("XIB 非対応") }

    // MARK: - Setup

    private func setupViews() {
        let hStack = NSStackView()
        hStack.orientation = .horizontal
        hStack.alignment = .centerY
        hStack.spacing = 12
        hStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hStack)

        // HiDPI セグメントコントロール
        segmentControl.segmentCount = 2
        segmentControl.setLabel("HiDPI", forSegment: 0)
        segmentControl.setLabel("すべて", forSegment: 1)
        segmentControl.trackingMode = .selectOne
        segmentControl.selectedSegment = hiDPIOnly ? 0 : 1
        segmentControl.target = self
        segmentControl.action = #selector(segmentChanged(_:))
        segmentControl.setContentHuggingPriority(.required, for: .horizontal)
        hStack.addArrangedSubview(segmentControl)

        // セパレーター
        let sep = NSBox()
        sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        hStack.addArrangedSubview(sep)
        sep.heightAnchor.constraint(equalToConstant: 18).isActive = true

        // レートラベル
        let rateLabel = NSTextField(labelWithString: "レート:")
        rateLabel.font = DesignTokens.Typography.sectionHeader
        rateLabel.textColor = DesignTokens.Colors.sectionHeader
        rateLabel.isSelectable = false
        rateLabel.setContentHuggingPriority(.required, for: .horizontal)
        hStack.addArrangedSubview(rateLabel)

        // レートピル群
        rateContainer.orientation = .horizontal
        rateContainer.alignment = .centerY
        rateContainer.spacing = 4
        hStack.addArrangedSubview(rateContainer)

        buildRatePills()

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: topAnchor),
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            hStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func buildRatePills() {
        rateContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (i, rate) in availableRates.enumerated() {
            let title = "\(String(format: "%g", rate))Hz"
            let pill = TogglePillButton(title: title)
            pill.tag = i
            pill.isToggled = selectedRates.contains(rate)
            pill.target = self
            pill.action = #selector(pillTapped(_:))
            rateContainer.addArrangedSubview(pill)
        }
    }

    // MARK: - Actions

    @objc private func segmentChanged(_ sender: NSSegmentedControl) {
        hiDPIOnly = sender.selectedSegment == 0
        onFilterChanged((hiDPIOnly, selectedRates))
    }

    @objc private func pillTapped(_ sender: TogglePillButton) {
        let rate = availableRates[sender.tag]
        if sender.isToggled {
            selectedRates.remove(rate)
        } else {
            selectedRates.insert(rate)
        }
        sender.isToggled = !sender.isToggled
        onFilterChanged((hiDPIOnly, selectedRates))
    }
}

// MARK: - TogglePillButton

/// トグル可能なピル形状ボタン
/// 選択時=アクセントカラー背景+白文字、非選択時=灰背景+通常文字
final class TogglePillButton: NSButton {

    var isToggled: Bool = false {
        didSet { needsDisplay = true }
    }

    init(title: String) {
        super.init(frame: .zero)
        self.title = title
        isBordered = false
        font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError("XIB 非対応") }

    override var intrinsicContentSize: NSSize {
        var s = super.intrinsicContentSize
        s.width += 12
        s.height = max(s.height, 20)
        return s
    }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(
            roundedRect: bounds,
            xRadius: bounds.height / 2,
            yRadius: bounds.height / 2
        )
        if isToggled {
            // ON: アクセント背景 + アクセント枠線
            NSColor.controlAccentColor.withAlphaComponent(0.25).setFill()
            path.fill()
            NSColor.controlAccentColor.setStroke()
            path.lineWidth = 1
            path.stroke()
        } else {
            // OFF: 塗りなし + セパレーター枠線のみ
            NSColor.separatorColor.setStroke()
            path.lineWidth = 1
            path.stroke()
        }

        // テキスト描画
        let textColor: NSColor = isToggled ? .labelColor : .tertiaryLabelColor
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font as Any,
            .foregroundColor: textColor,
        ]
        let str = NSAttributedString(string: title, attributes: attrs)
        let textSize = str.size()
        let textRect = NSRect(
            x: (bounds.width - textSize.width) / 2,
            y: (bounds.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        str.draw(in: textRect)
    }
}
