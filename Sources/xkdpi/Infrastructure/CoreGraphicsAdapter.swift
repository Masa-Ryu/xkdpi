import CoreGraphics
import AppKit

/// Adapter that converts CGDisplayMode to DisplayMode and wraps CoreGraphics APIs.
public struct CoreGraphicsAdapter: Sendable {

    public init() {}

    /// Converts CGDisplayMode to DisplayMode.
    /// Returns nil for invalid modes where id == 0.
    public func convert(_ cgMode: CGDisplayMode) -> DisplayMode? {
        // In the Xcode 26+ SDK, ioDisplayModeID is Int32.
        let modeID = cgMode.ioDisplayModeID
        guard modeID != 0 else { return nil }

        return DisplayMode(
            id: modeID,
            width: cgMode.width,
            height: cgMode.height,
            pixelWidth: cgMode.pixelWidth,
            pixelHeight: cgMode.pixelHeight,
            refreshRate: cgMode.refreshRate
        )
    }

    /// Fetches all available modes for the specified display.
    /// Uses kCGDisplayShowDuplicateLowResolutionModes to show all variants.
    /// Sort order: resolution descending, HiDPI first, refresh rate descending.
    public func allModes(for displayID: CGDirectDisplayID) -> [DisplayMode] {
        let options: CFDictionary = [
            kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue as Any
        ] as CFDictionary

        guard let cgModes = CGDisplayCopyAllDisplayModes(displayID, options) as? [CGDisplayMode] else {
            return []
        }
        return cgModes.compactMap { convert($0) }.sorted { a, b in
            if a.width != b.width { return a.width > b.width }
            if a.height != b.height { return a.height > b.height }
            if a.isHiDPI != b.isHiDPI { return a.isHiDPI }
            return a.refreshRate > b.refreshRate
        }
    }

    /// Fetches the current mode for the specified display.
    public func currentMode(for displayID: CGDirectDisplayID) -> DisplayMode? {
        guard let cgMode = CGDisplayCopyDisplayMode(displayID) else { return nil }
        return convert(cgMode)
    }

    /// Finds a CGDisplayMode by modeID.
    public func findCGMode(displayID: CGDirectDisplayID, modeID: Int32) -> CGDisplayMode? {
        let options: CFDictionary = [
            kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue as Any
        ] as CFDictionary

        guard let cgModes = CGDisplayCopyAllDisplayModes(displayID, options) as? [CGDisplayMode] else {
            return nil
        }
        return cgModes.first { $0.ioDisplayModeID == modeID }
    }

    /// Returns the physical size of the specified display in millimeters.
    /// Returns nil when CGDisplayScreenSize returns 0×0.
    public func physicalSizeMM(for displayID: CGDirectDisplayID) -> (width: Double, height: Double)? {
        let size = CGDisplayScreenSize(displayID)
        guard size.width > 0, size.height > 0 else { return nil }
        return (width: Double(size.width), height: Double(size.height))
    }

    /// Fetches the display name using NSScreen.
    /// The caller must guarantee main-thread execution.
    public func displayName(for displayID: CGDirectDisplayID) -> String {
        for screen in NSScreen.screens {
            if let num = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
               num == displayID {
                return screen.localizedName
            }
        }
        return "Display \(displayID)"
    }
}
