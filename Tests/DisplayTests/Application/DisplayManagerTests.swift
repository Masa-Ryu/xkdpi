import Testing
import CoreGraphics

@testable import xkdpi

struct DisplayManagerTests {

    private func makeMode(id: Int32 = 1) -> DisplayMode {
        DisplayMode(id: id, width: 2560, height: 1440,
                    pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0)
    }

    private func makeDisplay(id: CGDirectDisplayID = 1) -> Display {
        Display(id: id, name: "Test Display", builtin: true,
                currentMode: makeMode(), availableModes: [makeMode()])
    }

    @Test func fetchDisplays_returnsRepositoryResult() throws {
        let repo = MockDisplayRepository()
        repo.displaysToReturn = [makeDisplay(id: 1), makeDisplay(id: 2)]
        let manager = DisplayManager(repository: repo)

        let displays = try manager.fetchDisplays()

        #expect(displays.count == 2)
        #expect(repo.fetchDisplaysCallCount == 1)
    }

    @Test func fetchDisplays_emptyResult_returnsEmpty() throws {
        let repo = MockDisplayRepository()
        repo.displaysToReturn = []
        let manager = DisplayManager(repository: repo)

        let displays = try manager.fetchDisplays()

        #expect(displays.isEmpty)
    }

    @Test func fetchDisplays_repositoryThrows_propagatesError() throws {
        let repo = MockDisplayRepository()
        repo.shouldThrow = .fetchFailed
        let manager = DisplayManager(repository: repo)

        #expect(throws: DisplayError.fetchFailed) {
            try manager.fetchDisplays()
        }
    }
}
