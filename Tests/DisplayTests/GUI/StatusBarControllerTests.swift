import AppKit
import Testing

@testable import xkdpi

struct StatusBarControllerTests {

    @Test @MainActor func init_whenLoginItemDisabled_unchecksMenuItem() {
        let loginItems = MockLoginItemManager(isEnabled: false)
        let controller = makeController(loginItems: loginItems)

        #expect(controller.launchAtLoginMenuState == .off)
    }

    @Test @MainActor func init_whenLoginItemEnabled_checksMenuItem() {
        let loginItems = MockLoginItemManager(isEnabled: true)
        let controller = makeController(loginItems: loginItems)

        #expect(controller.launchAtLoginMenuState == .on)
    }

    @Test @MainActor func init_withAppVersion_showsVersionMenuItem() {
        let loginItems = MockLoginItemManager(isEnabled: false)
        let controller = makeController(loginItems: loginItems, appVersion: "1.2.3")

        #expect(controller.appVersionMenuTitle == "バージョン 1.2.3")
    }

    @Test @MainActor func toggleLaunchAtLogin_whenDisabled_registersAndChecksMenuItem() {
        let loginItems = MockLoginItemManager(isEnabled: false)
        let controller = makeController(loginItems: loginItems)

        controller.toggleLaunchAtLogin(nil)

        #expect(loginItems.setEnabledCalls == [true])
        #expect(controller.launchAtLoginMenuState == .on)
    }

    @Test @MainActor func toggleLaunchAtLogin_whenEnabled_unregistersAndUnchecksMenuItem() {
        let loginItems = MockLoginItemManager(isEnabled: true)
        let controller = makeController(loginItems: loginItems)

        controller.toggleLaunchAtLogin(nil)

        #expect(loginItems.setEnabledCalls == [false])
        #expect(controller.launchAtLoginMenuState == .off)
    }

    @Test @MainActor func toggleLaunchAtLogin_whenManagerThrows_reportsErrorAndRestoresState() {
        let loginItems = MockLoginItemManager(isEnabled: false)
        loginItems.errorToThrow = LoginItemTestError.failed
        var reportedErrors: [(String, String)] = []
        let controller = makeController(loginItems: loginItems) { title, message in
            reportedErrors.append((title, message))
        }

        controller.toggleLaunchAtLogin(nil)

        #expect(loginItems.setEnabledCalls == [true])
        #expect(controller.launchAtLoginMenuState == .off)
        #expect(reportedErrors.count == 1)
        #expect(reportedErrors[0].0 == "ログイン時起動の設定に失敗しました")
    }

    @MainActor
    private func makeController(
        loginItems: MockLoginItemManager,
        appVersion: String = "テスト版",
        showError: @escaping (String, String) -> Void = { _, _ in }
    ) -> StatusBarController {
        StatusBarController(
            loginItemManager: loginItems,
            appVersion: appVersion,
            openSettings: {},
            showError: showError
        )
    }
}

private final class MockLoginItemManager: LoginItemManaging {
    var isEnabled: Bool
    var setEnabledCalls: [Bool] = []
    var errorToThrow: Error?

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func setEnabled(_ enabled: Bool) throws {
        setEnabledCalls.append(enabled)

        if let errorToThrow {
            throw errorToThrow
        }

        isEnabled = enabled
    }
}

private enum LoginItemTestError: Error {
    case failed
}
