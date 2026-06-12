import Foundation

/// Settings entry persisted to UserDefaults.
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

/// Settings store backed by UserDefaults.
/// Key: "xkdpi.settings"; value: JSON-encoded [DisplaySetting].
public final class SettingsStore: @unchecked Sendable {

    private let defaults: UserDefaults
    private let settingsKey = "xkdpi.settings"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Public API

    /// Saves the settings array, replacing existing values completely.
    public func save(_ settings: [DisplaySetting]) {
        guard let data = try? makeEncoder().encode(settings) else { return }
        defaults.set(data, forKey: settingsKey)
    }

    /// Loads the settings array.
    public func load() -> [DisplaySetting] {
        guard let data = defaults.data(forKey: settingsKey) else { return [] }
        return (try? makeDecoder().decode([DisplaySetting].self, from: data)) ?? []
    }

    /// Saves one display setting, replacing any existing entry with the same displayID.
    public func save(setting: DisplaySetting) {
        var all = load()
        all.removeAll { $0.displayID == setting.displayID }
        all.append(setting)
        save(all)
    }

    /// Clears all settings.
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
