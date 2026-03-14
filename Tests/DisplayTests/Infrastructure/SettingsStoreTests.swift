import Testing
import Foundation

@testable import xkdpi

struct SettingsStoreTests {

    // テストごとに独立した UserDefaults スイートを使用（並列実行対応）
    private func makeStore() -> SettingsStore {
        let suiteName = "com.xkdpi.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return SettingsStore(defaults: defaults)
    }

    @Test func load_whenEmpty_returnsEmptyArray() {
        let store = makeStore()
        #expect(store.load().isEmpty)
    }

    @Test func save_thenLoad_roundTrips() {
        let store = makeStore()
        let setting = DisplaySetting(displayID: 1, modeID: 42)
        store.save([setting])

        let loaded = store.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].displayID == 1)
        #expect(loaded[0].modeID == 42)
    }

    @Test func saveSetting_sameDisplayID_overwritesPrevious() {
        let store = makeStore()
        store.save(setting: DisplaySetting(displayID: 1, modeID: 10))
        store.save(setting: DisplaySetting(displayID: 1, modeID: 99))

        let loaded = store.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].modeID == 99)
    }

    @Test func clear_removesAllSettings() {
        let store = makeStore()
        store.save([DisplaySetting(displayID: 1, modeID: 42)])
        store.clear()
        #expect(store.load().isEmpty)
    }

    @Test func save_multipleDisplays_persistsAll() {
        let store = makeStore()
        store.save([
            DisplaySetting(displayID: 1, modeID: 10),
            DisplaySetting(displayID: 2, modeID: 20),
        ])
        let loaded = store.load()
        #expect(loaded.count == 2)
    }
}
