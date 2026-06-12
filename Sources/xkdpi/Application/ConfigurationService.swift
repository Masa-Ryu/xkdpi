/// Service responsible for saving and restoring settings.
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

    /// Saves the selected mode to UserDefaults.
    public func saveSettings(display: Display, mode: DisplayMode) {
        let setting = DisplaySetting(displayID: display.id, modeID: mode.id)
        store.save(setting: setting)
        logger.info("Saving setting: \(display.name) -> \(mode.displayString)")
    }

    /// Loads saved settings and applies them to connected displays.
    /// Skips missing displays instead of treating them as errors.
    public func restoreSettings() throws {
        let saved = store.load()
        guard !saved.isEmpty else {
            logger.debug("No saved settings")
            return
        }

        let displays = try displayManager.fetchDisplays()
        logger.info("Restoring settings: \(saved.count) item(s)")

        for setting in saved {
            guard let display = displays.first(where: { $0.id == setting.displayID }) else {
                logger.debug("Display is not connected: id=\(setting.displayID)")
                continue
            }
            guard let mode = display.availableModes.first(where: { $0.id == setting.modeID }) else {
                logger.debug("Mode not found: id=\(setting.modeID)")
                continue
            }
            do {
                try modeSwitchService.switchMode(mode, for: display)
            } catch {
                logger.error("Failed to restore setting: \(display.name) -> \(error)")
            }
        }

        logger.info("Settings restore completed")
    }
}
