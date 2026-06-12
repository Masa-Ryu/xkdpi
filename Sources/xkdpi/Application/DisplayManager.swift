/// Service responsible for fetching and managing displays.
public final class DisplayManager: Sendable {

    private let repository: any DisplayRepository
    private let logger: Logger

    public init(repository: any DisplayRepository, logger: Logger = Logger()) {
        self.repository = repository
        self.logger = logger
    }

    /// Returns all connected displays.
    public func fetchDisplays() throws -> [Display] {
        logger.debug("Fetching displays")
        return try repository.fetchDisplays()
    }
}
