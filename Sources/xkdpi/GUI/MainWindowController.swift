import AppKit

/// xkdpi メインウィンドウ
/// ディスプレイ一覧とモード選択UIを表示し、モード切替・設定保存を行う
public final class MainWindowController: NSWindowController {

    // MARK: - Dependencies

    private let displayManager: DisplayManager
    private let modeSwitchService: ModeSwitchService
    private let configurationService: ConfigurationService
    private let logger: Logger

    // MARK: - UI Components

    /// ディスプレイ列を横並びに格納するコンテナ（各列は独立スクロール）
    private let columnRow = NSStackView()
    /// モード切替後の in-place 更新用（displayID → セクションビュー）
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

    required init?(coder: NSCoder) { fatalError("XIB 非対応") }

    // MARK: - Setup

    private func setupContentView() {
        guard let contentView = window?.contentView else { return }

        // ヘッダーラベル（固定）
        let header = NSTextField(labelWithString: "ディスプレイ設定")
        header.font = .boldSystemFont(ofSize: 16)
        header.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(header)

        // カラム行（各列に独立スクロールビューを持つ）
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

    /// ディスプレイ一覧を取得してUIを再描画する
    public func refreshDisplays() {
        do {
            let displays = try displayManager.fetchDisplays()
            updateUI(with: displays)
        } catch {
            logger.error("ディスプレイ取得失敗: \(error)")
            showErrorLabel("ディスプレイ情報を取得できませんでした")
        }
    }

    // MARK: - Private UI Update

    private static let columnWidth: CGFloat = 360
    private static let columnSpacing: CGFloat = 16
    private static let windowPadding: CGFloat = 48  // scroll bar + side margins

    private func updateUI(with displays: [Display]) {
        // ウィンドウ幅をディスプレイ数に合わせて調整（先に実行）
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
            showErrorLabel("ディスプレイが検出されませんでした")
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

            // columnRow の高さ全体を埋めるよう bottom 制約を追加
            colScroll.bottomAnchor.constraint(equalTo: columnRow.bottomAnchor).isActive = true
        }
    }

    private func handleModeSelection(_ mode: DisplayMode, for display: Display) {
        do {
            try modeSwitchService.switchMode(mode, for: display)
            configurationService.saveSettings(display: display, mode: mode)
            // UI 全再構築を避けフィルター状態を保持したままラベルと選択状態だけ更新
            sectionViews[display.id]?.updateCurrentMode(to: mode)
        } catch {
            logger.error("モード切替失敗: \(error)")
            showAlert(title: "モード切替に失敗しました", message: error.localizedDescription)
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
