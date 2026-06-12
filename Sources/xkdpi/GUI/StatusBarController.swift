import AppKit

/// ステータスバー項目とメニューを管理する
@MainActor
public final class StatusBarController: NSObject {

    private let statusItem: NSStatusItem
    private let loginItemManager: LoginItemManaging
    private let logger: Logger
    private let openSettings: () -> Void
    private let showError: (String, String) -> Void

    private let openSettingsItem = NSMenuItem(title: "ディスプレイ設定を開く", action: nil, keyEquivalent: "")
    private let launchAtLoginItem = NSMenuItem(title: "ログイン時に起動", action: nil, keyEquivalent: "")
    private let quitItem = NSMenuItem(title: "終了", action: nil, keyEquivalent: "q")

    public init(
        loginItemManager: LoginItemManaging,
        logger: Logger = Logger(label: "StatusBarController"),
        openSettings: @escaping () -> Void,
        showError: @escaping (String, String) -> Void
    ) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.loginItemManager = loginItemManager
        self.logger = logger
        self.openSettings = openSettings
        self.showError = showError
        super.init()

        setupStatusItem()
        updateLaunchAtLoginState()
    }

    public var launchAtLoginMenuState: NSControl.StateValue {
        launchAtLoginItem.state
    }

    @objc public func openSettingsFromMenu(_ sender: Any?) {
        openSettings()
    }

    @objc public func toggleLaunchAtLogin(_ sender: Any?) {
        let nextEnabled = !loginItemManager.isEnabled

        do {
            try loginItemManager.setEnabled(nextEnabled)
        } catch {
            logger.error("ログイン時起動の設定失敗: \(error)")
            showError("ログイン時起動の設定に失敗しました", error.localizedDescription)
        }

        updateLaunchAtLoginState()
    }

    @objc public func quit(_ sender: Any?) {
        NSApp.terminate(nil)
    }

    public func updateLaunchAtLoginState() {
        launchAtLoginItem.state = loginItemManager.isEnabled ? .on : .off
    }

    private func setupStatusItem() {
        statusItem.button?.title = "xkdpi"
        statusItem.button?.toolTip = "xkdpi"

        openSettingsItem.target = self
        openSettingsItem.action = #selector(openSettingsFromMenu(_:))

        launchAtLoginItem.target = self
        launchAtLoginItem.action = #selector(toggleLaunchAtLogin(_:))

        quitItem.target = self
        quitItem.action = #selector(quit(_:))

        let menu = NSMenu()
        menu.addItem(openSettingsItem)
        menu.addItem(.separator())
        menu.addItem(launchAtLoginItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)
        statusItem.menu = menu
    }
}
