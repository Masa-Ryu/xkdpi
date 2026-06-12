import CoreGraphics

/// xkdpi error definitions.
public enum DisplayError: Error, Equatable, Sendable {
    /// Failed to fetch display information.
    case fetchFailed
    /// The specified mode ID was not found.
    case modeNotFound(modeID: Int32)
    /// Failed to begin or complete CGDisplayConfiguration.
    case configFailed
    /// Failed to execute a mode switch, preserving CGError.rawValue.
    case switchFailed(Int32)
}
