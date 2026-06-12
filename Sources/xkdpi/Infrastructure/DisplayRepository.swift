import CoreGraphics

/// Repository protocol for display information.
/// DI boundary that makes MacDisplayRepository for real hardware and MockDisplayRepository for tests interchangeable.
public protocol DisplayRepository: Sendable {
    /// Returns all connected displays, including their available modes.
    func fetchDisplays() throws -> [Display]
    /// Returns all available modes for the specified display.
    func fetchModes(for displayID: CGDirectDisplayID) throws -> [DisplayMode]
    /// Returns the current mode for the specified display.
    func fetchCurrentMode(for displayID: CGDirectDisplayID) throws -> DisplayMode
    /// Switches the mode for the specified display, delegating to CoreGraphics.
    func switchMode(displayID: CGDirectDisplayID, to modeID: Int32) throws
}
