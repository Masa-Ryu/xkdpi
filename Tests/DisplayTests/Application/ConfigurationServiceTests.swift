import Testing
import Foundation
import CoreGraphics

@testable import xkdpi

struct ConfigurationServiceTests {

    private func makeMode(id: Int32, hiDPI: Bool = true) -> DisplayMode {
        DisplayMode(id: id, width: 2560, height: 1440,
                    pixelWidth: hiDPI ? 5120 : 2560, pixelHeight: hiDPI ? 2880 : 1440,
                    refreshRate: 60.0)
    }

    private func makeDisplay(id: CGDirectDisplayID, currentModeID: Int32 = 1) -> Display {
        let mode = makeMode(id: currentModeID)
        let altMode = makeMode(id: currentModeID + 1)
        return Display(id: id, name: "Display \(id)", builtin: id == 1,
                       currentMode: mode, availableModes: [mode, altMode])
    }

    private func makeStore() -> SettingsStore {
        let suiteName = "com.xkdpi.configtest.\(UUID().uuidString)"
        return SettingsStore(defaults: UserDefaults(suiteName: suiteName)!)
    }

    @Test func saveSettings_persistsDisplayIDAndModeID() throws {
        let store = makeStore()
        let repo = MockDisplayRepository()
        let switcher = ModeSwitchService(repository: repo, logger: Logger())
        let manager = DisplayManager(repository: repo)
        let service = ConfigurationService(store: store, displayManager: manager,
                                           modeSwitchService: switcher, logger: Logger())
        let display = makeDisplay(id: 1, currentModeID: 42)
        let mode = display.currentMode

        service.saveSettings(display: display, mode: mode)

        let saved = store.load()
        #expect(saved.count == 1)
        #expect(saved[0].displayID == 1)
        #expect(saved[0].modeID == 42)
    }

    @Test func restoreSettings_matchingDisplayAndMode_switchesMode() throws {
        let store = makeStore()
        let repo = MockDisplayRepository()
        let modifiedDisplay = Display(id: 1, name: "Display 1", builtin: true,
                                      currentMode: makeMode(id: 7),
                                      availableModes: [makeMode(id: 7), makeMode(id: 8)])
        repo.displaysToReturn = [modifiedDisplay]
        store.save([DisplaySetting(displayID: 1, modeID: 7)])

        let switcher = ModeSwitchService(repository: repo, logger: Logger())
        let manager = DisplayManager(repository: repo)
        let service = ConfigurationService(store: store, displayManager: manager,
                                           modeSwitchService: switcher, logger: Logger())

        try service.restoreSettings()

        #expect(repo.switchModeCalls.count == 1)
        #expect(repo.switchModeCalls[0].modeID == 7)
    }

    @Test func restoreSettings_noMatchingDisplay_skipsWithoutError() throws {
        let store = makeStore()
        let repo = MockDisplayRepository()
        repo.displaysToReturn = [makeDisplay(id: 2)]  // display 1 is not connected
        store.save([DisplaySetting(displayID: 1, modeID: 42)])

        let switcher = ModeSwitchService(repository: repo, logger: Logger())
        let manager = DisplayManager(repository: repo)
        let service = ConfigurationService(store: store, displayManager: manager,
                                           modeSwitchService: switcher, logger: Logger())

        try service.restoreSettings()

        #expect(repo.switchModeCalls.isEmpty)
    }

    @Test func restoreSettings_emptyStore_doesNothing() throws {
        let store = makeStore()
        let repo = MockDisplayRepository()
        repo.displaysToReturn = [makeDisplay(id: 1)]

        let switcher = ModeSwitchService(repository: repo, logger: Logger())
        let manager = DisplayManager(repository: repo)
        let service = ConfigurationService(store: store, displayManager: manager,
                                           modeSwitchService: switcher, logger: Logger())

        try service.restoreSettings()

        #expect(repo.switchModeCalls.isEmpty)
    }
}
