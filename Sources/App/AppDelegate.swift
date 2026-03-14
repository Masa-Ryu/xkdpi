import AppKit
import xkdpi

/// アプリケーションデリゲート
/// 依存グラフの構築・ウィンドウ表示・起動時設定復元を行う
public final class AppDelegate: NSObject, NSApplicationDelegate {

    private var windowController: MainWindowController?
    private let logger = Logger(label: "AppDelegate")

    public func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("xkdpi 起動")

        // 依存グラフの手動構築
        let adapter = CoreGraphicsAdapter()
        let repo = MacDisplayRepository(adapter: adapter, logger: logger)
        let store = SettingsStore()
        let manager = DisplayManager(repository: repo, logger: logger)
        let switcher = ModeSwitchService(repository: repo, logger: logger)
        let config = ConfigurationService(
            store: store,
            displayManager: manager,
            modeSwitchService: switcher,
            logger: logger
        )

        // ウィンドウを生成・表示
        let wc = MainWindowController(
            displayManager: manager,
            modeSwitchService: switcher,
            configurationService: config,
            logger: logger
        )
        windowController = wc
        wc.showWindow(nil)
        wc.refreshDisplays()

        // 起動時に保存された設定を復元
        do {
            try config.restoreSettings()
        } catch {
            logger.error("設定復元失敗: \(error)")
        }
    }

    /// 常駐型アプリ: ウィンドウを閉じてもプロセスを継続する
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
