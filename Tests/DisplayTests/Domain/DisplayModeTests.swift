import Testing

@testable import xkdpi

// MARK: - isHiDPI

struct DisplayModeTests {

    @Test func isHiDPI_bothPixelDimensionsExceedLogical_returnsTrue() {
        let mode = DisplayMode(id: 1, width: 1920, height: 1080,
                               pixelWidth: 3840, pixelHeight: 2160, refreshRate: 60.0)
        #expect(mode.isHiDPI == true)
    }

    @Test func isHiDPI_pixelDimensionsEqualLogical_returnsFalse() {
        let mode = DisplayMode(id: 2, width: 1920, height: 1080,
                               pixelWidth: 1920, pixelHeight: 1080, refreshRate: 60.0)
        #expect(mode.isHiDPI == false)
    }

    @Test func isHiDPI_onlyPixelWidthExceeds_returnsTrue() {
        let mode = DisplayMode(id: 3, width: 1920, height: 1080,
                               pixelWidth: 3840, pixelHeight: 1080, refreshRate: 60.0)
        #expect(mode.isHiDPI == true)
    }

    @Test func isHiDPI_onlyPixelHeightExceeds_returnsTrue() {
        let mode = DisplayMode(id: 4, width: 1920, height: 1080,
                               pixelWidth: 1920, pixelHeight: 2160, refreshRate: 60.0)
        #expect(mode.isHiDPI == true)
    }

    // MARK: - displayString

    @Test func displayString_hiDPI_includesHiDPILabelAndRate() {
        let mode = DisplayMode(id: 1, width: 2560, height: 1440,
                               pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0)
        #expect(mode.displayString == "2560\u{00D7}1440 (HiDPI) 60Hz")
    }

    @Test func displayString_nonHiDPI_includesRate() {
        let mode = DisplayMode(id: 2, width: 1920, height: 1080,
                               pixelWidth: 1920, pixelHeight: 1080, refreshRate: 60.0)
        #expect(mode.displayString == "1920\u{00D7}1080 60Hz")
    }

    @Test func displayString_120Hz_shows120Hz() {
        let mode = DisplayMode(id: 3, width: 2560, height: 1440,
                               pixelWidth: 5120, pixelHeight: 2880, refreshRate: 120.0)
        #expect(mode.displayString == "2560\u{00D7}1440 (HiDPI) 120Hz")
    }

    @Test func displayString_fractionalRate_showsDecimal() {
        let mode = DisplayMode(id: 4, width: 1920, height: 1080,
                               pixelWidth: 1920, pixelHeight: 1080, refreshRate: 59.94)
        #expect(mode.displayString == "1920\u{00D7}1080 59.94Hz")
    }

    @Test func displayString_sameResolutionDifferentRate_areUnique() {
        let mode60 = DisplayMode(id: 1, width: 2560, height: 1440,
                                 pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0)
        let mode120 = DisplayMode(id: 2, width: 2560, height: 1440,
                                  pixelWidth: 5120, pixelHeight: 2880, refreshRate: 120.0)
        #expect(mode60.displayString != mode120.displayString)
    }

    // MARK: - resolutionString

    @Test func resolutionString_hiDPI_includesHiDPILabel() {
        let mode = DisplayMode(id: 1, width: 2560, height: 1440,
                               pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0)
        #expect(mode.resolutionString == "2560\u{00D7}1440 (HiDPI)")
    }

    @Test func resolutionString_nonHiDPI_noLabel() {
        let mode = DisplayMode(id: 2, width: 1920, height: 1080,
                               pixelWidth: 1920, pixelHeight: 1080, refreshRate: 120.0)
        #expect(mode.resolutionString == "1920\u{00D7}1080")
    }

    @Test func resolutionString_ignoresRefreshRate() {
        let mode60 = DisplayMode(id: 1, width: 2560, height: 1440,
                                 pixelWidth: 5120, pixelHeight: 2880, refreshRate: 60.0)
        let mode120 = DisplayMode(id: 2, width: 2560, height: 1440,
                                  pixelWidth: 5120, pixelHeight: 2880, refreshRate: 120.0)
        #expect(mode60.resolutionString == mode120.resolutionString)
    }

    // MARK: - refreshRateString

    @Test func refreshRateString_integerRate_noDecimal() {
        let mode = DisplayMode(id: 1, width: 1920, height: 1080,
                               pixelWidth: 1920, pixelHeight: 1080, refreshRate: 120.0)
        #expect(mode.refreshRateString == "120Hz")
    }

    @Test func refreshRateString_fractionalRate_showsDecimal() {
        let mode = DisplayMode(id: 2, width: 1920, height: 1080,
                               pixelWidth: 1920, pixelHeight: 1080, refreshRate: 59.94)
        #expect(mode.refreshRateString == "59.94Hz")
    }

    @Test func displayString_equalsResolutionPlusRefreshRate() {
        let mode = DisplayMode(id: 1, width: 2560, height: 1440,
                               pixelWidth: 5120, pixelHeight: 2880, refreshRate: 120.0)
        #expect(mode.displayString == "\(mode.resolutionString) \(mode.refreshRateString)")
    }
}
