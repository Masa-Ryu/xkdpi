import Foundation

/// Display mode containing logical and pixel resolutions.
public struct DisplayMode: Equatable, Hashable, Sendable {

    /// CoreGraphics ioDisplayModeID.
    public let id: Int32
    /// Logical width in points.
    public let width: Int
    /// Logical height in points.
    public let height: Int
    /// Physical width in pixels.
    public let pixelWidth: Int
    /// Physical height in pixels.
    public let pixelHeight: Int
    /// Refresh rate in Hz.
    public let refreshRate: Double

    public init(
        id: Int32,
        width: Int,
        height: Int,
        pixelWidth: Int,
        pixelHeight: Int,
        refreshRate: Double
    ) {
        self.id = id
        self.width = width
        self.height = height
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.refreshRate = refreshRate
    }

    /// HiDPI check: true when the physical resolution is greater than the logical resolution.
    public var isHiDPI: Bool {
        pixelWidth > width || pixelHeight > height
    }

    /// Display string for the resolution portion, for example "2560×1440 (HiDPI)" or "1920×1080".
    /// Also used as the key for grouping modes with the same resolution and HiDPI setting.
    public var resolutionString: String {
        let res = "\(width)\u{00D7}\(height)"
        return isHiDPI ? "\(res) (HiDPI)" : res
    }

    /// Display string for the refresh rate, for example "120Hz" or "59.94Hz".
    public var refreshRateString: String {
        "\(String(format: "%g", refreshRate))Hz"
    }

    /// Full display string for the GUI, for example "2560×1440 (HiDPI) 120Hz".
    public var displayString: String {
        "\(resolutionString) \(refreshRateString)"
    }
}
