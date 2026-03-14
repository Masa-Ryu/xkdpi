import Testing
import CoreGraphics

@testable import xkdpi

struct DisplayTests {

    private func makeMode(id: Int32 = 1, width: Int = 1920, height: Int = 1080,
                          pixelWidth: Int = 3840, pixelHeight: Int = 2160) -> DisplayMode {
        DisplayMode(id: id, width: width, height: height,
                    pixelWidth: pixelWidth, pixelHeight: pixelHeight, refreshRate: 60.0)
    }

    @Test func display_init_setsAllProperties() {
        let mode = makeMode()
        let display = Display(id: 1, name: "Built-in Retina Display",
                              builtin: true, currentMode: mode)
        #expect(display.id == 1)
        #expect(display.name == "Built-in Retina Display")
        #expect(display.builtin == true)
        #expect(display.currentMode == mode)
        #expect(display.availableModes.isEmpty)
    }

    @Test func display_withAvailableModes_storesAll() {
        let mode1 = makeMode(id: 1)
        let mode2 = makeMode(id: 2, pixelWidth: 1920, pixelHeight: 1080)
        let display = Display(id: 2, name: "External Display",
                              builtin: false, currentMode: mode1,
                              availableModes: [mode1, mode2])
        #expect(display.availableModes.count == 2)
    }

    @Test func display_externalDisplay_hasBuiltinFalse() {
        let display = Display(id: 3, name: "External Display",
                              builtin: false, currentMode: makeMode())
        #expect(display.builtin == false)
    }

    // MARK: - modeGroups

    @Test func modeGroups_groupsByResolution() {
        // 2560×1440(HiDPI) × 2レート + 1920×1080 × 1レート → 2グループ
        let hiDPI60  = DisplayMode(id: 1, width: 2560, height: 1440,
                                   pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0)
        let hiDPI120 = DisplayMode(id: 2, width: 2560, height: 1440,
                                   pixelWidth: 5120, pixelHeight: 2880, refreshRate: 120.0)
        let fhd60    = DisplayMode(id: 3, width: 1920, height: 1080,
                                   pixelWidth: 1920, pixelHeight: 1080, refreshRate: 60.0)
        let display = Display(id: 1, name: "Test", builtin: false, currentMode: hiDPI60,
                              availableModes: [hiDPI60, hiDPI120, fhd60])

        let groups = display.modeGroups
        #expect(groups.count == 2)
        #expect(groups[0].resolutionString == "2560\u{00D7}1440 (HiDPI)")
        #expect(groups[0].modes.count == 2)
        #expect(groups[1].resolutionString == "1920\u{00D7}1080")
        #expect(groups[1].modes.count == 1)
    }

    @Test func modeGroups_preservesInsertionOrder() {
        let fhd = DisplayMode(id: 1, width: 1920, height: 1080,
                              pixelWidth: 1920, pixelHeight: 1080, refreshRate: 60.0)
        let qhd = DisplayMode(id: 2, width: 2560, height: 1440,
                              pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0)
        // fhd が先に並んでいる場合、グループ順も fhd が先
        let display = Display(id: 1, name: "Test", builtin: false, currentMode: fhd,
                              availableModes: [fhd, qhd])

        let groups = display.modeGroups
        #expect(groups[0].resolutionString == "1920\u{00D7}1080")
        #expect(groups[1].resolutionString == "2560\u{00D7}1440 (HiDPI)")
    }

    @Test func modeGroups_singleMode_oneGroup() {
        let mode = makeMode()
        let display = Display(id: 1, name: "Test", builtin: true, currentMode: mode,
                              availableModes: [mode])
        #expect(display.modeGroups.count == 1)
        #expect(display.modeGroups[0].modes.count == 1)
    }

    @Test func modeGroups_emptyAvailableModes_emptyGroups() {
        let display = Display(id: 1, name: "Test", builtin: true, currentMode: makeMode())
        #expect(display.modeGroups.isEmpty)
    }

    // MARK: - hiDPIModeGroups

    @Test func hiDPIModeGroups_filtersOutNonHiDPI() {
        // 2560×1440(HiDPI)×2レート + 1920×1080(non-HiDPI)×1レート → HiDPIグループのみ
        let hiDPI60  = DisplayMode(id: 1, width: 2560, height: 1440,
                                   pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0)
        let hiDPI120 = DisplayMode(id: 2, width: 2560, height: 1440,
                                   pixelWidth: 5120, pixelHeight: 2880, refreshRate: 120.0)
        let nonHiDPI = DisplayMode(id: 3, width: 1920, height: 1080,
                                   pixelWidth: 1920, pixelHeight: 1080, refreshRate: 60.0)
        let display = Display(id: 1, name: "Test", builtin: false, currentMode: hiDPI60,
                              availableModes: [hiDPI60, hiDPI120, nonHiDPI])

        let groups = display.hiDPIModeGroups
        #expect(groups.count == 1)
        #expect(groups[0].resolutionLabel == "2560\u{00D7}1440")
        #expect(groups[0].modes.count == 2)
    }

    @Test func hiDPIModeGroups_groupsByResolution() {
        // 2種の HiDPI 解像度 → 2グループ
        let qhd60  = DisplayMode(id: 1, width: 2560, height: 1440,
                                 pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0)
        let uhd60  = DisplayMode(id: 2, width: 3840, height: 2160,
                                 pixelWidth: 7680, pixelHeight: 4320, refreshRate: 60.0)
        let display = Display(id: 1, name: "Test", builtin: false, currentMode: qhd60,
                              availableModes: [qhd60, uhd60])

        let groups = display.hiDPIModeGroups
        #expect(groups.count == 2)
        #expect(groups[0].resolutionLabel == "2560\u{00D7}1440")
        #expect(groups[1].resolutionLabel == "3840\u{00D7}2160")
    }

    @Test func hiDPIModeGroups_preservesInsertionOrder() {
        // uhd が先に並んでいる場合、グループ順も uhd が先
        let uhd60  = DisplayMode(id: 1, width: 3840, height: 2160,
                                 pixelWidth: 7680, pixelHeight: 4320, refreshRate: 60.0)
        let qhd60  = DisplayMode(id: 2, width: 2560, height: 1440,
                                 pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0)
        let display = Display(id: 1, name: "Test", builtin: false, currentMode: uhd60,
                              availableModes: [uhd60, qhd60])

        let groups = display.hiDPIModeGroups
        #expect(groups[0].resolutionLabel == "3840\u{00D7}2160")
        #expect(groups[1].resolutionLabel == "2560\u{00D7}1440")
    }

    @Test func hiDPIModeGroups_noHiDPIModes_returnsEmpty() {
        let nonHiDPI = DisplayMode(id: 1, width: 1920, height: 1080,
                                   pixelWidth: 1920, pixelHeight: 1080, refreshRate: 60.0)
        let display = Display(id: 1, name: "Test", builtin: false, currentMode: nonHiDPI,
                              availableModes: [nonHiDPI])
        #expect(display.hiDPIModeGroups.isEmpty)
    }

    // MARK: - filteredModeGroups

    @Test func filteredModeGroups_hiDPIOnly_noRateFilter_showsAllHiDPIResolutions() {
        let hiDPI60  = DisplayMode(id: 1, width: 2560, height: 1440,
                                   pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0)
        let hiDPI120 = DisplayMode(id: 2, width: 2560, height: 1440,
                                   pixelWidth: 5120, pixelHeight: 2880, refreshRate: 120.0)
        let nonHiDPI = DisplayMode(id: 3, width: 1920, height: 1080,
                                   pixelWidth: 1920, pixelHeight: 1080, refreshRate: 60.0)
        let display = Display(id: 1, name: "Test", builtin: false, currentMode: hiDPI60,
                              availableModes: [hiDPI60, hiDPI120, nonHiDPI])

        let groups = display.filteredModeGroups(hiDPIOnly: true, rates: [])
        // HiDPI フィルター ON、レートフィルターなし → HiDPI 解像度のみ、ラベルに "(HiDPI)" なし
        #expect(groups.count == 1)
        #expect(groups[0].label == "2560\u{00D7}1440")
        #expect(groups[0].modes.count == 2)
    }

    @Test func filteredModeGroups_allModes_noRateFilter_includesNonHiDPI() {
        let hiDPI60  = DisplayMode(id: 1, width: 2560, height: 1440,
                                   pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0)
        let nonHiDPI = DisplayMode(id: 2, width: 1920, height: 1080,
                                   pixelWidth: 1920, pixelHeight: 1080, refreshRate: 60.0)
        let display = Display(id: 1, name: "Test", builtin: false, currentMode: hiDPI60,
                              availableModes: [hiDPI60, nonHiDPI])

        let groups = display.filteredModeGroups(hiDPIOnly: false, rates: [])
        // HiDPI フィルター OFF → HiDPI ラベルに "(HiDPI)" サフィックスあり
        #expect(groups.count == 2)
        #expect(groups[0].label == "2560\u{00D7}1440 (HiDPI)")
        #expect(groups[1].label == "1920\u{00D7}1080")
    }

    @Test func filteredModeGroups_rateFilter_removesResolutionWithOnlyOtherRate() {
        // 2560×1440(HiDPI): 60Hz のみ → 120Hz フィルターで消える
        let hiDPI60only = DisplayMode(id: 1, width: 2560, height: 1440,
                                      pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0)
        // 3840×2160(HiDPI): 120Hz あり → 残る
        let uhd120 = DisplayMode(id: 2, width: 3840, height: 2160,
                                 pixelWidth: 7680, pixelHeight: 4320, refreshRate: 120.0)
        let display = Display(id: 1, name: "Test", builtin: false, currentMode: hiDPI60only,
                              availableModes: [hiDPI60only, uhd120])

        let groups = display.filteredModeGroups(hiDPIOnly: true, rates: [120.0])
        #expect(groups.count == 1)
        #expect(groups[0].label == "3840\u{00D7}2160")
    }

    @Test func filteredModeGroups_rateFilter_keepsResolutionWithMatchingRate() {
        // 2560×1440(HiDPI): 60Hz + 120Hz → 120Hz フィルター適用後も残る
        let hiDPI60  = DisplayMode(id: 1, width: 2560, height: 1440,
                                   pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0)
        let hiDPI120 = DisplayMode(id: 2, width: 2560, height: 1440,
                                   pixelWidth: 5120, pixelHeight: 2880, refreshRate: 120.0)
        let display = Display(id: 1, name: "Test", builtin: false, currentMode: hiDPI60,
                              availableModes: [hiDPI60, hiDPI120])

        let groups = display.filteredModeGroups(hiDPIOnly: true, rates: [120.0])
        #expect(groups.count == 1)
        // 120Hz のみのモードが含まれる（60Hz は除外）
        #expect(groups[0].modes.count == 1)
        #expect(groups[0].modes[0].refreshRate == 120.0)
    }

    // MARK: - ppi

    @Test func ppi_27inch4K_returnsApprox163() throws {
        // 27 インチ 4K: physicalWidth ≈ 597mm, physicalHeight ≈ 336mm, native 3840×2160
        let native = DisplayMode(id: 1, width: 3840, height: 2160,
                                 pixelWidth: 3840, pixelHeight: 2160, refreshRate: 60.0)
        let display = Display(id: 1, name: "Test", builtin: false,
                              currentMode: native, availableModes: [native],
                              physicalWidthMM: 597, physicalHeightMM: 336)
        let ppi = try #require(display.ppi)
        #expect(abs(ppi - 163.0) < 2.0, "expected ~163 PPI, got \(ppi)")
    }

    @Test func ppi_zeroPhysicalSize_returnsNil() {
        let mode = DisplayMode(id: 1, width: 1920, height: 1080,
                               pixelWidth: 1920, pixelHeight: 1080, refreshRate: 60.0)
        let display = Display(id: 1, name: "Test", builtin: false, currentMode: mode,
                              availableModes: [mode])
        #expect(display.ppi == nil)
    }

    @Test func ppi_usesMaxPixelDimensionsAcrossModes() throws {
        // 最大 pixelWidth は 5120（HiDPI モード）
        let hiDPI = DisplayMode(id: 1, width: 2560, height: 1440,
                                pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0)
        let native = DisplayMode(id: 2, width: 3840, height: 2160,
                                 pixelWidth: 3840, pixelHeight: 2160, refreshRate: 60.0)
        let display = Display(id: 1, name: "Test", builtin: false, currentMode: native,
                              availableModes: [hiDPI, native],
                              physicalWidthMM: 597, physicalHeightMM: 336)
        let ppi = try #require(display.ppi)
        // nativePixelW=5120, nativePixelH=2880 → 対角5786px / 27in ≈ 217 PPI
        #expect(abs(ppi - 217.0) < 3.0, "expected ~217 PPI, got \(ppi)")
    }

    @Test func filteredModeGroups_emptyRates_showsAllMatchingHiDPIModes() {
        // レートフィルターが空（全チェック）= レートでの絞り込みなし
        let hiDPI60  = DisplayMode(id: 1, width: 2560, height: 1440,
                                   pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0)
        let hiDPI120 = DisplayMode(id: 2, width: 2560, height: 1440,
                                   pixelWidth: 5120, pixelHeight: 2880, refreshRate: 120.0)
        let display = Display(id: 1, name: "Test", builtin: false, currentMode: hiDPI60,
                              availableModes: [hiDPI60, hiDPI120])

        let groups = display.filteredModeGroups(hiDPIOnly: true, rates: [])
        #expect(groups[0].modes.count == 2)
    }
}
