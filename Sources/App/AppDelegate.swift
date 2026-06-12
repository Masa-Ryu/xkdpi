import AppKit
import xkdpi

/// Application delegate.
/// Builds the dependency graph, presents the window, and restores settings at launch.
@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {

    private var windowController: MainWindowController?
    private var statusBarController: StatusBarController?
    private let logger = Logger(label: "AppDelegate")

    public func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("xkdpi launched")

        // Build the dependency graph manually.
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

        let loginItems = LoginItemService()

        // Create the window. It is shown from the status bar action.
        let wc = MainWindowController(
            displayManager: manager,
            modeSwitchService: switcher,
            configurationService: config,
            logger: logger
        )
        windowController = wc

        statusBarController = StatusBarController(
            loginItemManager: loginItems,
            logger: Logger(label: "StatusBarController"),
            openSettings: { [weak self] in
                self?.showSettingsWindow()
            },
            showError: { [weak self] title, message in
                self?.showAlert(title: title, message: message)
            }
        )

        // Restore saved settings at launch.
        do {
            try config.restoreSettings()
        } catch {
            logger.error("Failed to restore settings: \(error)")
        }
    }

    /// Resident app: keep the process running when the window closes.
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    private func showSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)
        windowController?.refreshDisplays()
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning

        if let window = windowController?.window, window.isVisible {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
}
