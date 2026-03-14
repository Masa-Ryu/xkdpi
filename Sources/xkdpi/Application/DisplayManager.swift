/// ディスプレイ一覧の取得・管理を担うサービス
public final class DisplayManager: Sendable {

    private let repository: any DisplayRepository
    private let logger: Logger

    public init(repository: any DisplayRepository, logger: Logger = Logger()) {
        self.repository = repository
        self.logger = logger
    }

    /// 接続中のすべてのディスプレイを返す
    public func fetchDisplays() throws -> [Display] {
        logger.debug("ディスプレイ一覧取得")
        return try repository.fetchDisplays()
    }
}
