import Foundation

/// ディスプレイ表示モード（論理解像度とピクセル解像度を保持）
public struct DisplayMode: Equatable, Hashable, Sendable {

    /// CoreGraphics の ioDisplayModeID
    public let id: Int32
    /// 論理幅（ポイント）
    public let width: Int
    /// 論理高さ（ポイント）
    public let height: Int
    /// 物理幅（ピクセル）
    public let pixelWidth: Int
    /// 物理高さ（ピクセル）
    public let pixelHeight: Int
    /// リフレッシュレート（Hz）
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

    /// HiDPI 判定: 物理解像度が論理解像度より大きい場合に true
    public var isHiDPI: Bool {
        pixelWidth > width || pixelHeight > height
    }

    /// 解像度部分の表示文字列（例: "2560×1440 (HiDPI)" / "1920×1080"）
    /// 同じ解像度・HiDPI 設定のモードをグループ化するキーとしても使用する
    public var resolutionString: String {
        let res = "\(width)\u{00D7}\(height)"
        return isHiDPI ? "\(res) (HiDPI)" : res
    }

    /// リフレッシュレートの表示文字列（例: "120Hz" / "59.94Hz"）
    public var refreshRateString: String {
        "\(String(format: "%g", refreshRate))Hz"
    }

    /// GUI 表示用の完全な文字列（例: "2560×1440 (HiDPI) 120Hz"）
    public var displayString: String {
        "\(resolutionString) \(refreshRateString)"
    }
}
