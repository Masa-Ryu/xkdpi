import CoreGraphics
import AppKit

/// 実機 CoreGraphics を使用したディスプレイリポジトリ
/// 呼び出しはメインスレッド（NSApplication のメインループ）から行う前提
public final class MacDisplayRepository: DisplayRepository {

    private let adapter: CoreGraphicsAdapter
    private let logger: Logger

    public init(adapter: CoreGraphicsAdapter = CoreGraphicsAdapter(), logger: Logger = Logger()) {
        self.adapter = adapter
        self.logger = logger
    }

    // MARK: - DisplayRepository

    public func fetchDisplays() throws -> [Display] {
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: 16)
        var count: UInt32 = 0

        let result = CGGetActiveDisplayList(16, &displayIDs, &count)
        guard result == .success else {
            logger.error("ディスプレイ一覧取得失敗: CGError \(result.rawValue)")
            throw DisplayError.fetchFailed
        }

        logger.info("ディスプレイ検出: \(count)台")

        return try (0..<Int(count)).map { i in
            let id = displayIDs[i]
            let name = adapter.displayName(for: id)
            let builtin = CGDisplayIsBuiltin(id) != 0
            let modes = adapter.allModes(for: id)
            guard let currentMode = adapter.currentMode(for: id) else {
                throw DisplayError.fetchFailed
            }
            let physicalSize = adapter.physicalSizeMM(for: id)
            return Display(
                id: id,
                name: name,
                builtin: builtin,
                currentMode: currentMode,
                availableModes: modes,
                physicalWidthMM: physicalSize?.width,
                physicalHeightMM: physicalSize?.height
            )
        }
    }

    public func fetchModes(for displayID: CGDirectDisplayID) throws -> [DisplayMode] {
        let modes = adapter.allModes(for: displayID)
        if modes.isEmpty {
            throw DisplayError.fetchFailed
        }
        return modes
    }

    public func fetchCurrentMode(for displayID: CGDirectDisplayID) throws -> DisplayMode {
        guard let mode = adapter.currentMode(for: displayID) else {
            throw DisplayError.fetchFailed
        }
        return mode
    }

    public func switchMode(displayID: CGDirectDisplayID, to modeID: Int32) throws {
        guard let cgMode = adapter.findCGMode(displayID: displayID, modeID: modeID) else {
            logger.error("モードが見つかりません: displayID=\(displayID) modeID=\(modeID)")
            throw DisplayError.modeNotFound(modeID: modeID)
        }

        var configRef: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&configRef) == .success else {
            throw DisplayError.configFailed
        }

        let configError = CGConfigureDisplayWithDisplayMode(configRef, displayID, cgMode, nil)
        guard configError == .success else {
            CGCancelDisplayConfiguration(configRef)
            throw DisplayError.configFailed
        }

        let completeError = CGCompleteDisplayConfiguration(configRef, .forSession)
        guard completeError == .success else {
            CGCancelDisplayConfiguration(configRef)
            logger.error("モード切替失敗: CGError \(completeError.rawValue)")
            throw DisplayError.switchFailed(completeError.rawValue)
        }

        logger.info("モード切替成功: displayID=\(displayID) modeID=\(modeID)")
    }
}
