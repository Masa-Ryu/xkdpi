import Foundation

/// UserDefaults に永続化する設定エントリ
public struct DisplaySetting: Codable, Equatable, Sendable {
    public let displayID: UInt32
    public let modeID: Int32
    public let timestamp: Date

    public init(displayID: UInt32, modeID: Int32, timestamp: Date = Date()) {
        self.displayID = displayID
        self.modeID = modeID
        self.timestamp = timestamp
    }
}

/// UserDefaults を使用した設定ストア
/// キー: "xkdpi.settings"、値: JSON エンコードされた [DisplaySetting]
public final class SettingsStore: @unchecked Sendable {

    private let defaults: UserDefaults
    private let settingsKey = "xkdpi.settings"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Public API

    /// 設定配列を保存する（既存を完全上書き）
    public func save(_ settings: [DisplaySetting]) {
        guard let data = try? makeEncoder().encode(settings) else { return }
        defaults.set(data, forKey: settingsKey)
    }

    /// 設定配列を読み込む
    public func load() -> [DisplaySetting] {
        guard let data = defaults.data(forKey: settingsKey) else { return [] }
        return (try? makeDecoder().decode([DisplaySetting].self, from: data)) ?? []
    }

    /// 単一ディスプレイの設定を保存（同一 displayID があれば上書き）
    public func save(setting: DisplaySetting) {
        var all = load()
        all.removeAll { $0.displayID == setting.displayID }
        all.append(setting)
        save(all)
    }

    /// 全設定を消去する
    public func clear() {
        defaults.removeObject(forKey: settingsKey)
    }

    // MARK: - Private Helpers

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
