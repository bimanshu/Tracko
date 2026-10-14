import XCTest
@testable import Tracko

/// Keeps the colour system's promises (skill §9.2): conversions are right, every token fits
/// Display P3, the brand green is beyond sRGB, and every text pair has enough contrast.
/// design/tools/palette.py checks the same numbers outside Xcode.
final class ColorTests: XCTestCase {
    private func assertClose(_ a: (Double, Double, Double), _ b: (Double, Double, Double), _ accuracy: Double,
                             file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(a.0, b.0, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(a.1, b.1, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(a.2, b.2, accuracy: accuracy, file: file, line: line)
    }

    // MARK: Conversions

    func testWhiteAndBlack() {
        assertClose(OKLCH(1, 0, 0).displayP3, (1, 1, 1), 1e-4)
        assertClose(OKLCH(0, 0, 0).displayP3, (0, 0, 0), 1e-6)
    }

    func testSRGBRedRoundTrips() {
        // CSS Color 4: sRGB red is oklch(62.796% 0.25768 29.2339).
        let red = OKLCH(0.627955, 0.257683, 29.2339)
        assertClose(red.linearSRGB, (1, 0, 0), 1e-3)
        // The same red in Display P3.
        assertClose(red.displayP3, (0.9175, 0.2003, 0.1386), 2e-3)
    }

    func testContrastOfWhiteOnBlackIsTwentyOne() {
        XCTAssertEqual(OKLCH.contrast(OKLCH(1, 0, 0), OKLCH(0, 0, 0)), 21, accuracy: 0.01)
    }

    // MARK: Tokens

    func testEveryTokenFitsDisplayP3() {
        for colour in Palette.all {
            XCTAssertTrue(colour.isInDisplayP3, "\(colour) clips in Display P3")
        }
    }

    func testBrandGreenIsBeyondSRGB() {
        // Vivid on purpose: the accent needs P3 to look as intended.
        let (r, g, b) = Palette.green300.linearSRGB
        XCTAssertTrue([r, g, b].contains { $0 < 0 || $0 > 1 })
    }

    func testTextContrast() {
        let pairs: [(OKLCH, OKLCH, Double, String)] = [
            (Palette.neutral50, Palette.neutral950, 4.5, "text primary on canvas"),
            (Palette.neutral300, Palette.neutral950, 4.5, "text secondary on canvas"),
            (Palette.neutral500, Palette.neutral950, 4.5, "text tertiary on canvas"),
            (Palette.neutral50, Palette.neutral900, 4.5, "text primary on surface"),
            (Palette.neutral300, Palette.neutral900, 4.5, "text secondary on surface"),
            (Palette.neutral500, Palette.neutral900, 4.5, "text tertiary on surface"),
            (Palette.neutral950, Palette.neutral50, 4.5, "button label on the light pill"),
            (Palette.green300, Palette.neutral950, 3, "accent scores on canvas"),
            (Palette.green300, Palette.neutral900, 3, "accent scores on surface"),
            (Palette.neutral50, Palette.green600, 3, "logo at the brightest part of the glow"),
            (Palette.neutral600, Palette.neutral950, 3, "inactive page dots"),
        ]
        for (foreground, background, needed, name) in pairs {
            XCTAssertGreaterThanOrEqual(OKLCH.contrast(foreground, background), needed, name)
        }
    }

    func testRampsStepEvenlyInLightness() {
        let neutrals = [Palette.neutral950, Palette.neutral900, Palette.neutral850, Palette.neutral800,
                        Palette.neutral600, Palette.neutral500, Palette.neutral300, Palette.neutral50]
        XCTAssertEqual(neutrals.map(\.lightness), neutrals.map(\.lightness).sorted())
        XCTAssertEqual(Set([Palette.green900, Palette.green600, Palette.green300].map(\.hue)).count, 1,
                       "The green ramp keeps one hue")
    }
}
