import XCTest
@testable import Tracko

/// Keeps the colour system's promises (skill §9.2): conversions are right, every primitive fits
/// Display P3, the brand green is beyond sRGB, and every pair the app draws passes WCAG 2 and
/// APCA in both the standard and the Increase Contrast appearance.
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

    func testContrastOfWhiteOnBlack() {
        XCTAssertEqual(OKLCH.contrast(OKLCH(1, 0, 0), OKLCH(0, 0, 0)), 21, accuracy: 0.01)
        // APCA reference values: black on white Lc 106.0, white on black Lc −107.9.
        XCTAssertEqual(OKLCH.apca(text: OKLCH(0, 0, 0), background: OKLCH(1, 0, 0)), 106.04, accuracy: 0.1)
        XCTAssertEqual(OKLCH.apca(text: OKLCH(1, 0, 0), background: OKLCH(0, 0, 0)), -107.88, accuracy: 0.1)
    }

    // MARK: Tokens

    func testEveryPrimitiveFitsDisplayP3() {
        for colour in Palette.all {
            XCTAssertTrue(colour.isInDisplayP3, "\(colour) clips in Display P3")
        }
    }

    func testBrandGreenIsBeyondSRGB() {
        // Vivid on purpose: the accent needs P3 to look as intended.
        let (r, g, b) = Palette.green300.linearSRGB
        XCTAssertTrue([r, g, b].contains { $0 < 0 || $0 > 1 })
    }

    private enum Kind {
        case body, label, large, ui

        /// (WCAG 2 minimum ratio, APCA minimum |Lc|)
        var minimums: (Double, Double) {
            switch self {
            case .body: return (4.5, 75)
            case .label: return (4.5, 60)
            case .large: return (3, 45)
            case .ui: return (3, 30)
            }
        }
    }

    func testEveryPairPassesInBothAppearances() {
        typealias R = Theme.Roles
        let pairs: [(Role, Role, Kind, String)] = [
            (R.textPrimary, R.bgPage, .body, "headlines"),
            (R.textSecondary, R.bgPage, .body, "sublines"),
            (R.textTertiary, R.bgPage, .label, "phone labels (the phone screen is bgPage)"),
            (R.textInverse, R.bgInverse, .label, "the button label"),
            (R.textInverse, R.accent, .label, "a beaten set's tile"),
            (R.textPrimary, R.bgRaised, .label, "set tiles"),
            (R.accent, R.bgPage, .large, "the +% score"),
            (R.fillSubtle, R.bgPage, .ui, "inactive page dots"),
            (R.fillStrong, R.bgRaised, .ui, "a bar on its track"),
            (R.accent, R.bgRaised, .ui, "a beaten bar on its track"),
        ]
        for (foreground, background, kind, name) in pairs {
            let (wcag, apca) = kind.minimums
            for (text, page, appearance) in [
                (foreground.standard, background.standard, "standard"),
                (foreground.increased, background.increased, "Increase Contrast"),
            ] {
                XCTAssertGreaterThanOrEqual(OKLCH.contrast(text, page), wcag, "\(name), \(appearance), WCAG")
                XCTAssertGreaterThanOrEqual(abs(OKLCH.apca(text: text, background: page)), apca, "\(name), \(appearance), APCA")
            }
        }
        XCTAssertGreaterThanOrEqual(OKLCH.contrast(Palette.neutral50, Palette.green600), 3, "the logo on the glow")
    }

    func testIncreaseContrastWidensMutedRoles() {
        // At least 15 points of lightness further from the page, or as far as the ramp goes.
        typealias R = Theme.Roles
        for role in [R.textTertiary, R.fillSubtle, R.border] {
            XCTAssertGreaterThanOrEqual(role.increased.lightness - role.standard.lightness, 0.15 - 1e-9)
        }
        XCTAssertEqual(R.textSecondary.increased, Palette.neutral50)
    }

    func testRampsHoldTheirShape() {
        let neutrals = [Palette.neutral950, Palette.neutral850, Palette.neutral800, Palette.neutral600,
                        Palette.neutral400, Palette.neutral300, Palette.neutral100, Palette.neutral50]
        XCTAssertEqual(neutrals.map(\.lightness), neutrals.map(\.lightness).sorted())
        XCTAssertEqual(Set([Palette.green600, Palette.green300].map(\.hue)).count, 1,
                       "The green ramp keeps one hue")
    }
}
