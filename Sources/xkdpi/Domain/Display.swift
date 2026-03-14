import CoreGraphics

/// 接続中のディスプレイ情報
public struct Display: Sendable {

    /// CoreGraphics ディスプレイID（CGDirectDisplayID = UInt32）
    public let id: CGDirectDisplayID
    /// ディスプレイ名（NSScreen.localizedName から取得）
    public let name: String
    /// 内蔵ディスプレイか否か
    public let builtin: Bool
    /// 現在の表示モード
    public var currentMode: DisplayMode
    /// 利用可能な表示モード一覧（HiDPI 含む全モード）
    public var availableModes: [DisplayMode]
    /// 物理的な横幅（mm）。取得できない場合は nil
    public let physicalWidthMM: Double?
    /// 物理的な縦幅（mm）。取得できない場合は nil
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

    /// PPI（pixels per inch）。物理サイズが不明な場合は nil。
    /// 全モードの最大ピクセル解像度と物理寸法から算出する。
    public var ppi: Double? {
        guard let w = physicalWidthMM, let h = physicalHeightMM, w > 0, h > 0 else { return nil }
        let maxPW = availableModes.map { $0.pixelWidth }.max() ?? currentMode.pixelWidth
        let maxPH = availableModes.map { $0.pixelHeight }.max() ?? currentMode.pixelHeight
        let diagPx = (Double(maxPW) * Double(maxPW) + Double(maxPH) * Double(maxPH)).squareRoot()
        let diagInch = (w * w + h * h).squareRoot() / 25.4
        return diagPx / diagInch
    }

    /// availableModes を resolutionString でグループ化する（挿入順を保持）
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

    /// HiDPI モードのみを解像度でグループ化した一覧（挿入順を保持）
    /// resolutionLabel は "2560×1440" 形式（"(HiDPI)" サフィックスなし）
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

    /// Apple Retina 目標 PPI（220）を基に算出した推奨 HiDPI モード。
    /// 物理サイズ不明・HiDPI モード無しの場合は nil。
    public var recommendedMode: DisplayMode? {
        guard let w = physicalWidthMM, w > 0 else { return nil }
        guard ppi != nil else { return nil }  // physicalHeightMM ガードを ppi に委譲

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

    /// HiDPI フィルターとリフレッシュレートフィルターを組み合わせたグループ一覧（GUI フィルター用）
    ///
    /// - Parameters:
    ///   - hiDPIOnly: `true` のとき HiDPI モードのみを対象とする
    ///   - rates: 含めるリフレッシュレートの集合。空のとき全レートを含める
    /// - Returns: ラベルとモード群の配列（挿入順を保持）
    ///   - `hiDPIOnly: true` のとき、ラベルは "2560×1440" 形式（"(HiDPI)" サフィックスなし）
    ///   - `hiDPIOnly: false` のとき、ラベルは `resolutionString` 形式（HiDPI には "(HiDPI)" サフィックスあり）
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
