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
    private let versionItem: NSMenuItem
    private let launchAtLoginItem = NSMenuItem(title: "ログイン時に起動", action: nil, keyEquivalent: "")
    private let quitItem = NSMenuItem(title: "終了", action: nil, keyEquivalent: "q")

    public init(
        loginItemManager: LoginItemManaging,
        appVersion: String? = nil,
        logger: Logger = Logger(label: "StatusBarController"),
        openSettings: @escaping () -> Void,
        showError: @escaping (String, String) -> Void
    ) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.loginItemManager = loginItemManager
        self.logger = logger
        self.openSettings = openSettings
        self.showError = showError
        self.versionItem = NSMenuItem(title: "バージョン \(appVersion ?? StatusBarController.defaultAppVersion())", action: nil, keyEquivalent: "")
        super.init()

        setupStatusItem()
        updateLaunchAtLoginState()
    }

    public var launchAtLoginMenuState: NSControl.StateValue {
        launchAtLoginItem.state
    }

    public var appVersionMenuTitle: String {
        versionItem.title
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
        if let image = Self.makeStatusBarIcon() {
            statusItem.button?.image = image
            statusItem.button?.imagePosition = .imageOnly
        } else {
            statusItem.button?.title = "xk"
        }
        statusItem.button?.toolTip = "xkdpi"

        openSettingsItem.target = self
        openSettingsItem.action = #selector(openSettingsFromMenu(_:))

        launchAtLoginItem.target = self
        launchAtLoginItem.action = #selector(toggleLaunchAtLogin(_:))

        quitItem.target = self
        quitItem.action = #selector(quit(_:))

        versionItem.isEnabled = false

        let menu = NSMenu()
        menu.addItem(openSettingsItem)
        menu.addItem(versionItem)
        menu.addItem(.separator())
        menu.addItem(launchAtLoginItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    private static func makeStatusBarIcon() -> NSImage? {
        guard
            let iconURL = Bundle.module.url(forResource: "StatusBarIcon", withExtension: "svg"),
            let image = NSImage(contentsOf: iconURL)
        else {
            return nil
        }

        image.isTemplate = true
        image.size = NSSize(width: 20, height: 14)
        return image
    }

    private static func defaultAppVersion() -> String {
        let infoDictionary = Bundle.main.infoDictionary
        let shortVersion = infoDictionary?["CFBundleShortVersionString"] as? String
        let buildVersion = infoDictionary?["CFBundleVersion"] as? String

        switch (shortVersion, buildVersion) {
        case let (short?, build?) where short != build:
            return "\(short) (\(build))"
        case let (short?, _):
            return short
        case let (_, build?):
            return build
        default:
            return "開発版"
        }
    }
}
