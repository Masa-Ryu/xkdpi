import CoreGraphics
import AppKit

/// CGDisplayMode を DisplayMode に変換し、CoreGraphics API をラップするアダプタ
public struct CoreGraphicsAdapter: Sendable {

    public init() {}

    /// CGDisplayMode を DisplayMode に変換する
    /// 無効なモード（id == 0）は nil を返す
    public func convert(_ cgMode: CGDisplayMode) -> DisplayMode? {
        // Xcode 26+ SDK では ioDisplayModeID は Int32
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

    /// 指定ディスプレイの利用可能な全モードを取得する
    /// kCGDisplayShowDuplicateLowResolutionModes を指定して全バリアントを表示
    /// ソート順: 解像度 降順 → HiDPI 優先 → リフレッシュレート 降順
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

    /// 指定ディスプレイの現在のモードを取得する
    public func currentMode(for displayID: CGDirectDisplayID) -> DisplayMode? {
        guard let cgMode = CGDisplayCopyDisplayMode(displayID) else { return nil }
        return convert(cgMode)
    }

    /// CGDisplayMode を modeID で検索する
    public func findCGMode(displayID: CGDirectDisplayID, modeID: Int32) -> CGDisplayMode? {
        let options: CFDictionary = [
            kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue as Any
        ] as CFDictionary

        guard let cgModes = CGDisplayCopyAllDisplayModes(displayID, options) as? [CGDisplayMode] else {
            return nil
        }
        return cgModes.first { $0.ioDisplayModeID == modeID }
    }

    /// 指定ディスプレイの物理サイズをミリメートル単位で返す。
    /// CGDisplayScreenSize が 0×0 を返した場合は nil。
    public func physicalSizeMM(for displayID: CGDirectDisplayID) -> (width: Double, height: Double)? {
        let size = CGDisplayScreenSize(displayID)
        guard size.width > 0, size.height > 0 else { return nil }
        return (width: Double(size.width), height: Double(size.height))
    }

    /// NSScreen を使ってディスプレイ名を取得する
    /// 呼び出し元はメインスレッドを保証すること
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
