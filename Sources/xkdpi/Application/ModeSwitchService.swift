/// 表示モード切替を担うサービス
/// モードの存在確認（Application層の責務）と実際の切替（Infrastructure層に委譲）を行う
public final class ModeSwitchService: Sendable {

    private let repository: any DisplayRepository
    private let logger: Logger

    public init(repository: any DisplayRepository, logger: Logger = Logger()) {
        self.repository = repository
        self.logger = logger
    }

    /// 指定ディスプレイのモードを切替える
    /// mode が display.availableModes に含まれない場合は DisplayError.modeNotFound をスロー
    public func switchMode(_ mode: DisplayMode, for display: Display) throws {
        guard display.availableModes.contains(mode) else {
            logger.error("モードが存在しません: displayID=\(display.id) modeID=\(mode.id)")
            throw DisplayError.modeNotFound(modeID: mode.id)
        }

        logger.info("モード切替開始: \(display.name) → \(mode.displayString)")
        try repository.switchMode(displayID: display.id, to: mode.id)
        logger.info("モード切替完了: \(display.name) → \(mode.displayString)")
    }
}
