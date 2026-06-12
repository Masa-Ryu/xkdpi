/// Service responsible for switching display modes.
/// Validates mode existence in the application layer and delegates switching to infrastructure.
public final class ModeSwitchService: Sendable {

    private let repository: any DisplayRepository
    private let logger: Logger

    public init(repository: any DisplayRepository, logger: Logger = Logger()) {
        self.repository = repository
        self.logger = logger
    }

    /// Switches the mode for the specified display.
    /// Throws DisplayError.modeNotFound when mode is not included in display.availableModes.
    public func switchMode(_ mode: DisplayMode, for display: Display) throws {
        guard display.availableModes.contains(mode) else {
            logger.error("Mode not found: displayID=\(display.id) modeID=\(mode.id)")
            throw DisplayError.modeNotFound(modeID: mode.id)
        }

        logger.info("Starting mode switch: \(display.name) -> \(mode.displayString)")
        try repository.switchMode(displayID: display.id, to: mode.id)
        logger.info("Mode switch completed: \(display.name) -> \(mode.displayString)")
    }
}
