import CoreGraphics

@testable import xkdpi

/// テスト用モックリポジトリ
/// スタブ値の設定、呼び出し記録、エラー注入をサポートする
final class MockDisplayRepository: DisplayRepository, @unchecked Sendable {

    // MARK: - Stubbed return values

    var displaysToReturn: [Display] = []
    var modesToReturn: [CGDirectDisplayID: [DisplayMode]] = [:]
    var currentModeToReturn: [CGDirectDisplayID: DisplayMode] = [:]

    // MARK: - Call recording

    private(set) var switchModeCalls: [(displayID: CGDirectDisplayID, modeID: Int32)] = []
    private(set) var fetchDisplaysCallCount = 0

    // MARK: - Error injection

    var shouldThrow: DisplayError? = nil

    // MARK: - DisplayRepository

    func fetchDisplays() throws -> [Display] {
        fetchDisplaysCallCount += 1
        if let err = shouldThrow { throw err }
        return displaysToReturn
    }

    func fetchModes(for displayID: CGDirectDisplayID) throws -> [DisplayMode] {
        if let err = shouldThrow { throw err }
        return modesToReturn[displayID] ?? []
    }

    func fetchCurrentMode(for displayID: CGDirectDisplayID) throws -> DisplayMode {
        if let err = shouldThrow { throw err }
        guard let mode = currentModeToReturn[displayID] else {
            throw DisplayError.fetchFailed
        }
        return mode
    }

    func switchMode(displayID: CGDirectDisplayID, to modeID: Int32) throws {
        if let err = shouldThrow { throw err }
        switchModeCalls.append((displayID: displayID, modeID: modeID))
    }
}
