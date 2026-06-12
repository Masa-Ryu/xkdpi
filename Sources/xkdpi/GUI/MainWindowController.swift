import AppKit

/// Main xkdpi window.
/// Displays connected displays and mode selection UI, then switches and saves modes.
public final class MainWindowController: NSWindowController {

    // MARK: - Dependencies

    private let displayManager: DisplayManager
    private let modeSwitchService: ModeSwitchService
    private let configurationService: ConfigurationService
    private let logger: Logger

    // MARK: - UI Components

    /// Container that lays out display columns horizontally. Each column scrolls independently.
    private let columnRow = NSStackView()
    /// Section views used for in-place updates after mode switches, keyed by display ID.
    private var sectionViews: [CGDirectDisplayID: DisplaySectionView] = [:]

    // MARK: - Init

    public init(
        displayManager: DisplayManager,
        modeSwitchService: ModeSwitchService,
        configurationService: ConfigurationService,
        logger: Logger = Logger()
    ) {
        self.displayManager = displayManager
        self.modeSwitchService = modeSwitchService
        self.configurationService = configurationService
        self.logger = logger

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "xkdpi"
        window.center()
        window.setFrameAutosaveName("xkdpi.MainWindow")

        super.init(window: window)
        setupContentView()
    }

    required init?(coder: NSCoder) { fatalError("XIB is not supported") }

    // MARK: - Setup

    private func setupContentView() {
        guard let contentView = window?.contentView else { return }

        // Fixed header label.
        let header = NSTextField(labelWithString: "Display Settings")
        header.font = .boldSystemFont(ofSize: 16)
        header.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(header)

        // Column row. Each column owns an independent scroll view.
        columnRow.orientation = .horizontal
        columnRow.alignment = .top
        columnRow.spacing = Self.columnSpacing
        columnRow.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(columnRow)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            header.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            columnRow.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            columnRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            columnRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            columnRow.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    // MARK: - Public API

    /// Fetches displays and redraws the UI.
    public func refreshDisplays() {
        do {
            let displays = try displayManager.fetchDisplays()
            updateUI(with: displays)
        } catch {
            logger.error("Failed to fetch displays: \(error)")
            showErrorLabel("Could not fetch display information")
        }
    }

    // MARK: - Private UI Update

    private static let columnWidth: CGFloat = 360
    private static let columnSpacing: CGFloat = 16
    private static let windowPadding: CGFloat = 48  // scroll bar + side margins

    private func updateUI(with displays: [Display]) {
        // Adjust the window width to the number of displays before rebuilding content.
        if !displays.isEmpty, let window = window {
            let count = CGFloat(displays.count)
            let targetWidth = Self.columnWidth * count
                            + Self.columnSpacing * (count - 1)
                            + Self.windowPadding
            var frame = window.frame
            let delta = max(420, targetWidth) - frame.size.width
            frame.size.width = max(420, targetWidth)
            frame.origin.x -= (delta / 2)
            window.setFrame(frame, display: true, animate: false)
        }

        columnRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        sectionViews.removeAll()

        if displays.isEmpty {
            showErrorLabel("No displays were detected")
            return
        }

        for display in displays {
            let sectionView = DisplaySectionView(display: display) { [weak self] selectedMode in
                self?.handleModeSelection(selectedMode, for: display)
            }
            sectionView.translatesAutoresizingMaskIntoConstraints = false
            sectionViews[display.id] = sectionView
            let colScroll = NSScrollView()
            colScroll.hasVerticalScroller = true
            colScroll.autohidesScrollers = true
            colScroll.drawsBackground = false
            colScroll.translatesAutoresizingMaskIntoConstraints = false
            colScroll.documentView = sectionView

            let clipView = colScroll.contentView
            NSLayoutConstraint.activate([
                sectionView.topAnchor.constraint(equalTo: clipView.topAnchor),
                sectionView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
                sectionView.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
            ])

            colScroll.widthAnchor.constraint(equalToConstant: Self.columnWidth).isActive = true
            columnRow.addArrangedSubview(colScroll)

            // Add a bottom constraint so the scroll view fills the full columnRow height.
            colScroll.bottomAnchor.constraint(equalTo: columnRow.bottomAnchor).isActive = true
        }
    }

    private func handleModeSelection(_ mode: DisplayMode, for display: Display) {
        do {
            try modeSwitchService.switchMode(mode, for: display)
            configurationService.saveSettings(display: display, mode: mode)
            // Avoid rebuilding the whole UI so filters are preserved while labels and selection update.
            sectionViews[display.id]?.updateCurrentMode(to: mode)
        } catch {
            logger.error("Failed to switch mode: \(error)")
            showAlert(title: "Failed to switch mode", message: error.localizedDescription)
        }
    }

    private func showErrorLabel(_ message: String) {
        columnRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let label = NSTextField(labelWithString: message)
        label.textColor = .secondaryLabelColor
        columnRow.addArrangedSubview(label)
    }

    private func showAlert(title: String, message: String) {
        guard let window = window else { return }
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.beginSheetModal(for: window)
    }
}
