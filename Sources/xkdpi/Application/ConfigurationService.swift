/// 設定の保存・復元を担うサービス
public final class ConfigurationService: Sendable {

    private let store: SettingsStore
    private let displayManager: DisplayManager
    private let modeSwitchService: ModeSwitchService
    private let logger: Logger

    public init(
        store: SettingsStore,
        displayManager: DisplayManager,
        modeSwitchService: ModeSwitchService,
        logger: Logger = Logger()
    ) {
        self.store = store
        self.displayManager = displayManager
        self.modeSwitchService = modeSwitchService
        self.logger = logger
    }

    /// 選択されたモードを UserDefaults に保存する
    public func saveSettings(display: Display, mode: DisplayMode) {
        let setting = DisplaySetting(displayID: display.id, modeID: mode.id)
        store.save(setting: setting)
        logger.info("設定保存: \(display.name) → \(mode.displayString)")
    }

    /// 保存された設定を読み込み、接続中のディスプレイに適用する
    /// 対応するディスプレイが見つからない場合はスキップする（エラーにしない）
    public func restoreSettings() throws {
        let saved = store.load()
        guard !saved.isEmpty else {
            logger.debug("保存された設定なし")
            return
        }

        let displays = try displayManager.fetchDisplays()
        logger.info("設定復元開始: \(saved.count)件")

        for setting in saved {
            guard let display = displays.first(where: { $0.id == setting.displayID }) else {
                logger.debug("ディスプレイが接続されていません: id=\(setting.displayID)")
                continue
            }
            guard let mode = display.availableModes.first(where: { $0.id == setting.modeID }) else {
                logger.debug("モードが見つかりません: id=\(setting.modeID)")
                continue
            }
            do {
                try modeSwitchService.switchMode(mode, for: display)
            } catch {
                logger.error("設定復元失敗: \(display.name) → \(error)")
            }
        }

        logger.info("設定復元完了")
    }
}
