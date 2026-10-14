import SwiftUI

/// A colour in OKLCH: perceptual lightness (0–1), chroma (0 to about 0.37) and hue in degrees.
///
/// Tokens are written in OKLCH because its numbers behave: equal lightness steps look equal,
/// and hue stays put as lightness changes. Colours render in Display P3, so the brand green can
/// be more vivid than sRGB allows. `design/tools/palette.py` checks gamut and contrast for every
/// token; the tests in `ColorTests` keep the same promises in code.
struct OKLCH: Hashable, Sendable {
    var lightness: Double
    var chroma: Double
    var hue: Double

    init(_ lightness: Double, _ chroma: Double, _ hue: Double) {
        self.lightness = lightness
        self.chroma = chroma
        self.hue = hue
    }

    var color: Color {
        let (r, g, b) = displayP3
        return Color(.displayP3, red: r, green: g, blue: b, opacity: 1)
    }

    /// Gamma-encoded Display P3 components, clipped to 0...1.
    var displayP3: (Double, Double, Double) {
        let (r, g, b) = Self.linearSRGBToLinearP3(linearSRGB)
        return (Self.encode(r), Self.encode(g), Self.encode(b))
    }

    /// True when the colour fits Display P3 without clipping.
    var isInDisplayP3: Bool {
        let (r, g, b) = Self.linearSRGBToLinearP3(linearSRGB)
        let tolerance = 1e-4
        return [r, g, b].allSatisfy { $0 >= -tolerance && $0 <= 1 + tolerance }
    }

    /// Linear-light sRGB, unclipped: components outside 0...1 are outside sRGB.
    var linearSRGB: (Double, Double, Double) {
        Self.oklabToLinearSRGB(oklab)
    }

    var oklab: (l: Double, a: Double, b: Double) {
        let radians = hue * .pi / 180
        return (l: lightness, a: chroma * cos(radians), b: chroma * sin(radians))
    }

    /// WCAG 2 relative luminance.
    var relativeLuminance: Double {
        let (r, g, b) = linearSRGB
        return 0.2126390 * r + 0.7151687 * g + 0.0721923 * b
    }

    /// WCAG 2 contrast ratio between two colours, 1...21.
    static func contrast(_ first: OKLCH, _ second: OKLCH) -> Double {
        let a = first.relativeLuminance
        let b = second.relativeLuminance
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    /// Mixes two colours in OKLab: `amount` 0 is `self`, 1 is `other`. OKLab keeps the
    /// midpoints evenly bright, where an sRGB mix would sag and grey out.
    func mixed(with other: OKLCH, amount: Double) -> Color {
        let a = oklab
        let b = other.oklab
        let t = min(max(amount, 0), 1)
        let mix = (l: a.l + (b.l - a.l) * t, a: a.a + (b.a - a.a) * t, b: a.b + (b.b - a.b) * t)
        let (r, g, bl) = Self.linearSRGBToLinearP3(Self.oklabToLinearSRGB(mix))
        return Color(.displayP3, red: Self.encode(r), green: Self.encode(g), blue: Self.encode(bl), opacity: 1)
    }

    // MARK: Conversions (Björn Ottosson's OKLab, and the standard sRGB and P3 matrices)

    static func oklabToLinearSRGB(_ lab: (l: Double, a: Double, b: Double)) -> (Double, Double, Double) {
        let l = pow(lab.l + 0.3963377774 * lab.a + 0.2158037573 * lab.b, 3)
        let m = pow(lab.l - 0.1055613458 * lab.a - 0.0638541728 * lab.b, 3)
        let s = pow(lab.l - 0.0894841775 * lab.a - 1.2914855480 * lab.b, 3)
        return (
            4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
            -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
            -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
        )
    }

    static func linearSRGBToLinearP3(_ rgb: (Double, Double, Double)) -> (Double, Double, Double) {
        // sRGB → XYZ (D65) → Display P3, combined.
        let (r, g, b) = rgb
        return (
            0.8224621 * r + 0.1775380 * g + 0.0000000 * b,
            0.0331941 * r + 0.9668058 * g + 0.0000000 * b,
            0.0170827 * r + 0.0723974 * g + 0.9105199 * b
        )
    }

    /// The sRGB transfer curve, which Display P3 shares. Clips to 0...1.
    static func encode(_ linear: Double) -> Double {
        let c = min(max(linear, 0), 1)
        return c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1 / 2.4) - 0.055
    }
}

extension Color {
    init(_ oklch: OKLCH) {
        self = oklch.color
    }
}
