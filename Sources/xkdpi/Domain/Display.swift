import CoreGraphics

/// Connected display information.
public struct Display: Sendable {

    /// CoreGraphics display ID (CGDirectDisplayID = UInt32).
    public let id: CGDirectDisplayID
    /// Display name from NSScreen.localizedName.
    public let name: String
    /// Whether this is a built-in display.
    public let builtin: Bool
    /// Current display mode.
    public var currentMode: DisplayMode
    /// All available display modes, including HiDPI modes.
    public var availableModes: [DisplayMode]
    /// Physical width in millimeters, or nil when unavailable.
    public let physicalWidthMM: Double?
    /// Physical height in millimeters, or nil when unavailable.
    public let physicalHeightMM: Double?

    public init(
        id: CGDirectDisplayID,
        name: String,
        builtin: Bool,
        currentMode: DisplayMode,
        availableModes: [DisplayMode] = [],
        physicalWidthMM: Double? = nil,
        physicalHeightMM: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.builtin = builtin
        self.currentMode = currentMode
        self.availableModes = availableModes
        self.physicalWidthMM = physicalWidthMM
        self.physicalHeightMM = physicalHeightMM
    }

    /// PPI (pixels per inch), or nil when the physical size is unknown.
    /// Calculated from the maximum pixel resolution across all modes and the physical dimensions.
    public var ppi: Double? {
        guard let w = physicalWidthMM, let h = physicalHeightMM, w > 0, h > 0 else { return nil }
        let maxPW = availableModes.map { $0.pixelWidth }.max() ?? currentMode.pixelWidth
        let maxPH = availableModes.map { $0.pixelHeight }.max() ?? currentMode.pixelHeight
        let diagPx = (Double(maxPW) * Double(maxPW) + Double(maxPH) * Double(maxPH)).squareRoot()
        let diagInch = (w * w + h * h).squareRoot() / 25.4
        return diagPx / diagInch
    }

    /// Groups availableModes by resolutionString while preserving insertion order.
    public var modeGroups: [(resolutionString: String, modes: [DisplayMode])] {
        var dict: [String: [DisplayMode]] = [:]
        var order: [String] = []
        for mode in availableModes {
            let key = mode.resolutionString
            if dict[key] == nil { order.append(key) }
            dict[key, default: []].append(mode)
        }
        return order.map { ($0, dict[$0]!) }
    }

    /// Groups only HiDPI modes by resolution while preserving insertion order.
    /// resolutionLabel uses the "2560×1440" format without a "(HiDPI)" suffix.
    public var hiDPIModeGroups: [(resolutionLabel: String, modes: [DisplayMode])] {
        var dict: [String: [DisplayMode]] = [:]
        var order: [String] = []
        for mode in availableModes where mode.isHiDPI {
            let key = "\(mode.width)\u{00D7}\(mode.height)"
            if dict[key] == nil { order.append(key) }
            dict[key, default: []].append(mode)
        }
        return order.map { ($0, dict[$0]!) }
    }

    /// Recommended HiDPI mode calculated from Apple's Retina target PPI (220).
    /// Returns nil when physical size is unknown or no HiDPI modes exist.
    public var recommendedMode: DisplayMode? {
        guard let w = physicalWidthMM, w > 0 else { return nil }
        guard ppi != nil else { return nil }  // Delegate the physicalHeightMM guard to ppi.

        let targetLogicalWidth = (w / 25.4) * (220.0 / 2.0)

        let hiDPIGroups = hiDPIModeGroups
        guard !hiDPIGroups.isEmpty else { return nil }

        let bestGroup = hiDPIGroups.min { a, b in
            let aw = Double(a.modes.first?.width ?? 0)
            let bw = Double(b.modes.first?.width ?? 0)
            return abs(aw - targetLogicalWidth) < abs(bw - targetLogicalWidth)
        }
        return bestGroup?.modes.max { $0.refreshRate < $1.refreshRate }
    }

    /// Groups modes using the HiDPI and refresh-rate filters for GUI filtering.
    ///
    /// - Parameters:
    ///   - hiDPIOnly: When true, includes only HiDPI modes.
    ///   - rates: Refresh rates to include. An empty set includes all rates.
    /// - Returns: Label and mode groups while preserving insertion order.
    ///   - When `hiDPIOnly` is true, labels use the "2560×1440" format without a "(HiDPI)" suffix.
    ///   - When `hiDPIOnly` is false, labels use `resolutionString`, including "(HiDPI)" for HiDPI modes.
    public func filteredModeGroups(hiDPIOnly: Bool, rates: Set<Double>) -> [(label: String, modes: [DisplayMode])] {
        var filtered = availableModes
        if hiDPIOnly {
            filtered = filtered.filter { $0.isHiDPI }
        }
        if !rates.isEmpty {
            filtered = filtered.filter { rates.contains($0.refreshRate) }
        }
        var dict: [String: [DisplayMode]] = [:]
        var order: [String] = []
        for mode in filtered {
            let label = hiDPIOnly
                ? "\(mode.width)\u{00D7}\(mode.height)"
                : mode.resolutionString
            if dict[label] == nil { order.append(label) }
            dict[label, default: []].append(mode)
        }
        return order.map { ($0, dict[$0]!) }
    }
}
