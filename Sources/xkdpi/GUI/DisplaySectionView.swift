import AppKit

// MARK: - HzBadge

/// Label that displays a refresh rate as a pill-shaped badge.
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

    required init?(coder: NSCoder) { fatalError("XIB is not supported") }

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

/// View that displays information for one display.
///
/// Filters visible resolutions by HiDPI and refresh rate.
/// Clicking a resolution radio button applies it immediately using the highest refresh-rate mode.
public final class DisplaySectionView: NSView {

    // MARK: - Properties

    private var display: Display
    private var onModeSelected: (DisplayMode) -> Void

    /// Filter that shows only HiDPI modes. Defaults to on.
    private var hiDPIFilterEnabled: Bool = true
    /// Filter for refresh rates to show. Defaults to all rates.
    private var selectedRates: Set<Double>
    /// All unique refresh rates in descending order, used for checkbox tag indexes.
    private var availableRates: [Double] = []

    /// Currently selected resolution.
    private var selectedRes: (width: Int, height: Int)

    private let resStack = NSStackView()
    private let rateStack = NSStackView()
    /// Current mode label, retained so mode switches can update only the text.
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

    required init?(coder: NSCoder) { fatalError("XIB is not supported") }

    // MARK: - Public API

    /// Called after a mode switch. Preserves filters and updates only the current label and selection.
    public func updateCurrentMode(to mode: DisplayMode) {
        display.currentMode = mode
        currentModeLabel.stringValue = "Current: \(mode.displayString)"
        selectedRes = (mode.width, mode.height)
        rebuildResolutionButtons()
    }

    // MARK: - Active groups with HiDPI and rate filters applied

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

        // Display name and type badge.
        let nameRow = NSStackView()
        nameRow.orientation = .horizontal
        nameRow.alignment = .centerY
        nameRow.spacing = 8
        let nameLabel = makeLabel(display.name, bold: true, size: 14)
        let typeLabel = makeLabel(display.builtin ? "Built-in" : "External", bold: false, size: 11)
        typeLabel.textColor = display.builtin ? .systemBlue : .secondaryLabelColor
        nameRow.addArrangedSubview(nameLabel)
        nameRow.addArrangedSubview(typeLabel)
        container.addArrangedSubview(nameRow)

        // Current mode.
        currentModeLabel.stringValue = "Current: \(display.currentMode.displayString)"
        currentModeLabel.font = .systemFont(ofSize: 12)
        currentModeLabel.textColor = .secondaryLabelColor
        currentModeLabel.isSelectable = false
        container.addArrangedSubview(currentModeLabel)

        // Separator.
        let sep = NSBox()
        sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(sep)
        sep.widthAnchor.constraint(equalTo: container.widthAnchor).isActive = true

        // HiDPI filter checkbox.
        let filterCheck = NSButton(checkboxWithTitle: "Show HiDPI modes only",
                                   target: self, action: #selector(hiDPIFilterToggled(_:)))
        filterCheck.state = .on
        container.addArrangedSubview(filterCheck)

        // Refresh-rate filter checkboxes.
        container.addArrangedSubview(makeSectionLabel("Refresh Rate"))
        rateStack.orientation = .vertical
        rateStack.alignment = .leading
        rateStack.spacing = 4
        container.addArrangedSubview(rateStack)
        buildRateCheckboxes()

        // Resolution radio buttons.
        resStack.orientation = .vertical
        resStack.alignment = .leading
        resStack.spacing = 4
        container.addArrangedSubview(resStack)

        rebuildResolutionButtons()
    }

    // MARK: - Rate Checkbox Construction

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

    // MARK: - Resolution Button Rebuild

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
                resStack.addArrangedSubview(makeLabel("No available modes", bold: false, size: 12))
                return
            }

            // Match the recommended label to the filteredModeGroups label format.
            let recommendedLabel: String? = recommended.map { rec in
                hiDPIFilterEnabled
                    ? "\(rec.width)\u{00D7}\(rec.height)"
                    : rec.resolutionString
            }

            // Recommended section.
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

            // Other Modes section.
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
        // Remove "⭐ " (star + space = 2 chars) to restore the label.
        let label = String(sender.title.dropFirst(2))
        if let group = activeGroups().first(where: { $0.label == label }),
           let mode = group.modes.max(by: { $0.refreshRate < $1.refreshRate }) {
            selectedRes = (mode.width, mode.height)
            onModeSelected(mode)
        }
    }

    @objc private func resolutionButtonTapped(_ sender: NSButton) {
        // Apply the highest-rate mode from the selected group immediately.
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

    /// Creates a pill-shaped Hz badge.
    private func makeHzBadge(_ text: String) -> HzBadge {
        HzBadge(text: text)
    }

    /// Creates a horizontal row with a radio button and Hz badges.
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

        // Display refresh rates as badges in descending order.
        let rates = modes.map { $0.refreshRate }.sorted(by: >)
        for rate in rates {
            row.addArrangedSubview(makeHzBadge("\(String(format: "%g", rate))Hz"))
        }

        return row
    }
}
