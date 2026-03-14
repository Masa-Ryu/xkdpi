import Testing
import CoreGraphics

@testable import xkdpi

struct ModeSwitchServiceTests {

    private func makeMode(id: Int32, hiDPI: Bool = true) -> DisplayMode {
        DisplayMode(id: id, width: 2560, height: 1440,
                    pixelWidth: hiDPI ? 5120 : 2560, pixelHeight: hiDPI ? 2880 : 1440,
                    refreshRate: 60.0)
    }

    private func makeDisplay(id: CGDirectDisplayID = 1, modes: [DisplayMode]) -> Display {
        Display(id: id, name: "Test Display", builtin: true,
                currentMode: modes[0], availableModes: modes)
    }

    @Test func switchMode_validMode_callsRepository() throws {
        let repo = MockDisplayRepository()
        let mode = makeMode(id: 42)
        let display = makeDisplay(modes: [mode])
        let service = ModeSwitchService(repository: repo, logger: Logger())

        try service.switchMode(mode, for: display)

        #expect(repo.switchModeCalls.count == 1)
        #expect(repo.switchModeCalls[0].displayID == display.id)
        #expect(repo.switchModeCalls[0].modeID == mode.id)
    }

    @Test func switchMode_modeNotInAvailableModes_throwsModeNotFound() throws {
        let repo = MockDisplayRepository()
        let availableMode = makeMode(id: 1)
        let otherMode = makeMode(id: 99)
        let display = makeDisplay(modes: [availableMode])
        let service = ModeSwitchService(repository: repo, logger: Logger())

        #expect(throws: DisplayError.modeNotFound(modeID: 99)) {
            try service.switchMode(otherMode, for: display)
        }
        #expect(repo.switchModeCalls.isEmpty)
    }

    @Test func switchMode_repositoryThrows_propagatesError() throws {
        let repo = MockDisplayRepository()
        repo.shouldThrow = .configFailed
        let mode = makeMode(id: 1)
        let display = makeDisplay(modes: [mode])
        let service = ModeSwitchService(repository: repo, logger: Logger())

        #expect(throws: DisplayError.configFailed) {
            try service.switchMode(mode, for: display)
        }
    }
}
