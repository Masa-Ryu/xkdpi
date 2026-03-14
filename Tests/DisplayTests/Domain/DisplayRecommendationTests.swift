import Testing
import CoreGraphics
@testable import xkdpi

struct DisplayRecommendationTests {

    private func make4KModes() -> [DisplayMode] {
        [
            DisplayMode(id: 10, width: 3840, height: 2160, pixelWidth: 7680, pixelHeight: 4320, refreshRate: 60.0),
            DisplayMode(id: 8,  width: 3008, height: 1692, pixelWidth: 6016, pixelHeight: 3384, refreshRate: 120.0),
            DisplayMode(id: 7,  width: 3008, height: 1692, pixelWidth: 6016, pixelHeight: 3384, refreshRate: 60.0),
            DisplayMode(id: 6,  width: 2560, height: 1440, pixelWidth: 5120, pixelHeight: 2880, refreshRate: 120.0),
            DisplayMode(id: 5,  width: 2560, height: 1440, pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0),
            DisplayMode(id: 2,  width: 3840, height: 2160, pixelWidth: 3840, pixelHeight: 2160, refreshRate: 60.0),
            DisplayMode(id: 1,  width: 1920, height: 1080, pixelWidth: 1920, pixelHeight: 1080, refreshRate: 60.0),
        ]
    }

    @Test func recommendedMode_27inch4K_returns2560x1440HiDPI() throws {
        let display = Display(id: 1, name: "27\" 4K", builtin: false,
                              currentMode: make4KModes().last!,
                              availableModes: make4KModes(),
                              physicalWidthMM: 597, physicalHeightMM: 336)
        let mode = try #require(display.recommendedMode)
        #expect(mode.width == 2560 && mode.height == 1440 && mode.isHiDPI)
    }

    @Test func recommendedMode_32inch4K_returns3008x1692HiDPI() throws {
        let display = Display(id: 2, name: "32\" 4K", builtin: false,
                              currentMode: make4KModes().last!,
                              availableModes: make4KModes(),
                              physicalWidthMM: 708, physicalHeightMM: 398)
        let mode = try #require(display.recommendedMode)
        #expect(mode.width == 3008 && mode.height == 1692 && mode.isHiDPI)
    }

    @Test func recommendedMode_noPhysicalSize_returnsNil() {
        let display = Display(id: 3, name: "Test", builtin: false,
                              currentMode: make4KModes().last!,
                              availableModes: make4KModes())
        #expect(display.recommendedMode == nil)
    }

    @Test func recommendedMode_noHiDPIModes_returnsNil() {
        let nonHiDPI = [DisplayMode(id: 1, width: 1920, height: 1080,
                                    pixelWidth: 1920, pixelHeight: 1080, refreshRate: 60.0)]
        let display = Display(id: 4, name: "Test", builtin: false,
                              currentMode: nonHiDPI[0], availableModes: nonHiDPI,
                              physicalWidthMM: 597, physicalHeightMM: 336)
        #expect(display.recommendedMode == nil)
    }

    @Test func recommendedMode_returnsHighestRefreshRateInGroup() throws {
        let display = Display(id: 5, name: "Test", builtin: false,
                              currentMode: make4KModes().last!,
                              availableModes: make4KModes(),
                              physicalWidthMM: 597, physicalHeightMM: 336)
        let mode = try #require(display.recommendedMode)
        #expect(mode.refreshRate == 120.0)
    }

    @Test func recommendedMode_zeroPhysicalDimension_returnsNil() {
        let display = Display(id: 6, name: "Test", builtin: false,
                              currentMode: make4KModes().last!,
                              availableModes: make4KModes(),
                              physicalWidthMM: 0, physicalHeightMM: 336)
        #expect(display.recommendedMode == nil)
    }

    @Test func recommendedMode_27inch5K_returns2560x1440HiDPI() throws {
        // 27インチ 5K iMac (5120×2880 native, 597mm)
        // targetLogicalWidth = 2585 → 最近傍 2560×1440 HiDPI
        // ← 4K と同じ物理サイズなので同じ推奨結果（解像度ではなく物理特性で決まる）
        let modes5K = [
            DisplayMode(id: 10, width: 2560, height: 1440,
                        pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0),  // exact 2x
            DisplayMode(id: 9,  width: 2048, height: 1152,
                        pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0),
            DisplayMode(id: 8,  width: 1920, height: 1080,
                        pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0),
            DisplayMode(id: 1,  width: 5120, height: 2880,
                        pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0),  // native non-HiDPI
        ]
        let display = Display(id: 7, name: "iMac 5K", builtin: true,
                              currentMode: modes5K.last!,
                              availableModes: modes5K,
                              physicalWidthMM: 597, physicalHeightMM: 336)
        let mode = try #require(display.recommendedMode)
        #expect(mode.width == 2560 && mode.height == 1440 && mode.isHiDPI)
    }
}
