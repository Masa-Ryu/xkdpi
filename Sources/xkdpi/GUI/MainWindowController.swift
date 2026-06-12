import AppKit

/// xkdpi メインウィンドウ
/// NSSplitView による左右2ペイン構成: 左=ディスプレイ一覧、右=詳細ペイン
public final class MainWindowController: NSWindowController {

    // MARK: - Dependencies

    private let displayManager: DisplayManager
    private let modeSwitchService: ModeSwitchService
    private let configurationService: ConfigurationService
    private let logger: Logger

    // MARK: - UI Components

    private let splitView = NSSplitView()
    private let sidebarView = SidebarView(frame: .zero)
    private let detailContainer = NSView()

    // MARK: - State

    private var displays: [Display] = []
    private var selectedDisplayID: CGDirectDisplayID?
    /// フィルター状態保持: ディスプレイ切替時に DetailPaneView を再利用する
    private var detailPaneCache: [CGDirectDisplayID: DetailPaneView] = [:]

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
            contentRect: NSRect(x: 0, y: 0,
                                width: DesignTokens.Layout.windowWidth,
                                height: DesignTokens.Layout.windowHeight),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "xkdpi"
        window.minSize = NSSize(width: DesignTokens.Layout.windowMinWidth,
                                height: DesignTokens.Layout.windowMinHeight)
        window.center()
        window.setFrameAutosaveName("xkdpi.MainWindow")

        super.init(window: window)
        setupContentView()
    }

    required init?(coder: NSCoder) { fatalError("XIB 非対応") }

    // MARK: - Setup

    private func setupContentView() {
        guard let contentView = window?.contentView else { return }

        // NSSplitView（左右分割）
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.delegate = self
        splitView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(splitView)

        // 左: SidebarView
        sidebarView.translatesAutoresizingMaskIntoConstraints = false
        splitView.addArrangedSubview(sidebarView)
        sidebarView.onDisplaySelected = { [weak self] display in
            self?.showDetail(for: display)
        }

        // 右: Detail Container
        detailContainer.translatesAutoresizingMaskIntoConstraints = false
        splitView.addArrangedSubview(detailContainer)

        NSLayoutConstraint.activate([
            splitView.topAnchor.constraint(equalTo: contentView.topAnchor),
            splitView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            splitView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            sidebarView.widthAnchor.constraint(equalToConstant: DesignTokens.Layout.sidebarWidth),
        ])
    }

    // MARK: - Public API

    /// ディスプレイ一覧を取得してUIを再描画する
    public func refreshDisplays() {
        do {
            let fetchedDisplays = try displayManager.fetchDisplays()
            displays = fetchedDisplays
            detailPaneCache.removeAll()
            sidebarView.displays = fetchedDisplays

            if let first = fetchedDisplays.first {
                sidebarView.selectedDisplayID = first.id
                showDetail(for: first)
            } else {
                showEmptyState()
            }
        } catch {
            logger.error("ディスプレイ取得失敗: \(error)")
            showErrorLabel("ディスプレイ情報を取得できませんでした")
        }
    }

    // MARK: - Detail Management

    private func showDetail(for display: Display) {
        selectedDisplayID = display.id

        // キャッシュから取得 or 新規生成
        let pane: DetailPaneView
        if let cached = detailPaneCache[display.id] {
            pane = cached
        } else {
            pane = DetailPaneView(display: display)
            pane.onModeSelected = { [weak self] mode in
                self?.handleModeSelection(mode, for: display)
            }
            detailPaneCache[display.id] = pane
        }

        // コンテナの子を差し替え
        detailContainer.subviews.forEach { $0.removeFromSuperview() }
        pane.translatesAutoresizingMaskIntoConstraints = false
        detailContainer.addSubview(pane)
        NSLayoutConstraint.activate([
            pane.topAnchor.constraint(equalTo: detailContainer.topAnchor),
            pane.leadingAnchor.constraint(equalTo: detailContainer.leadingAnchor),
            pane.trailingAnchor.constraint(equalTo: detailContainer.trailingAnchor),
            pane.bottomAnchor.constraint(equalTo: detailContainer.bottomAnchor),
        ])
    }

    // MARK: - Mode Selection

    private func handleModeSelection(_ mode: DisplayMode, for display: Display) {
        do {
            try modeSwitchService.switchMode(mode, for: display)
            configurationService.saveSettings(display: display, mode: mode)

            // display の currentMode を更新
            if let index = displays.firstIndex(where: { $0.id == display.id }) {
                displays[index].currentMode = mode
                // Hero + 選択状態を更新
                detailPaneCache[display.id]?.updateCurrentMode(to: mode)
                // サイドバー行を更新
                sidebarView.updateRow(for: display.id, display: displays[index])
            }
        } catch {
            logger.error("モード切替失敗: \(error)")
            showAlert(title: "モード切替に失敗しました", message: error.localizedDescription)
        }
    }

    // MARK: - Empty / Error States

    private func showEmptyState() {
        detailContainer.subviews.forEach { $0.removeFromSuperview() }
        let label = NSTextField(labelWithString: "ディスプレイが検出されませんでした")
        label.textColor = .secondaryLabelColor
        label.font = DesignTokens.Typography.body
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        detailContainer.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: detailContainer.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: detailContainer.centerYAnchor),
        ])
    }

    private func showErrorLabel(_ message: String) {
        detailContainer.subviews.forEach { $0.removeFromSuperview() }
        let label = NSTextField(labelWithString: message)
        label.textColor = .secondaryLabelColor
        label.font = DesignTokens.Typography.body
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        detailContainer.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: detailContainer.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: detailContainer.centerYAnchor),
        ])
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

// MARK: - NSSplitViewDelegate

extension MainWindowController: NSSplitViewDelegate {
    public func splitView(
        _ splitView: NSSplitView,
        constrainMinCoordinate proposedMinimumPosition: CGFloat,
        ofSubviewAt dividerIndex: Int
    ) -> CGFloat {
        DesignTokens.Layout.sidebarMinWidth
    }

    public func splitView(
        _ splitView: NSSplitView,
        constrainMaxCoordinate proposedMaximumPosition: CGFloat,
        ofSubviewAt dividerIndex: Int
    ) -> CGFloat {
        DesignTokens.Layout.sidebarMaxWidth
    }

    public func splitView(
        _ splitView: NSSplitView,
        canCollapseSubview subview: NSView
    ) -> Bool {
        false
    }
}
