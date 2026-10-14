import SwiftUI

// Design tokens (skill §9). Views use `Theme`, `TypeScale`, `Space`, `Radius` and `Motion`,
// never raw values. Keep the OKLCH numbers identical to design/tools/palette.py, which checks
// their gamut and contrast.

/// Primitives: ramps named by hue and step. Views never use these directly; `Theme` names
/// what each one is for.
enum Palette {
    // Neutral ramp: a hint of the brand hue, chroma kept low.
    static let neutral950 = OKLCH(0.090, 0.004, 160)
    static let neutral900 = OKLCH(0.170, 0.008, 160)
    static let neutral850 = OKLCH(0.225, 0.010, 160)
    static let neutral800 = OKLCH(0.290, 0.012, 160)
    static let neutral600 = OKLCH(0.480, 0.012, 160)
    static let neutral500 = OKLCH(0.640, 0.012, 160)
    static let neutral300 = OKLCH(0.800, 0.010, 160)
    static let neutral50 = OKLCH(0.975, 0.005, 160)

    // Green ramp: the brand. One hue end to end; vivid in the middle, softer at the ends.
    static let green900 = OKLCH(0.330, 0.085, 152)
    static let green600 = OKLCH(0.500, 0.170, 152)
    static let green300 = OKLCH(0.850, 0.235, 152)

    static let all = [
        neutral950, neutral900, neutral850, neutral800, neutral600, neutral500, neutral300, neutral50,
        green900, green600, green300,
    ]
}

/// Semantic tokens: what each colour is for. Green means growth, and is the brand.
enum Theme {
    // MARK: Surfaces

    /// The app background: near-black, so the glow and the 3D heroes carry the light.
    static let canvas = Color(Palette.neutral950)
    /// Screens and cards that sit on the canvas.
    static let surface = Color(Palette.neutral900)
    /// Cards on cards, tracks behind bars.
    static let surfaceRaised = Color(Palette.neutral850)
    /// Dividers and outlines that only give structure.
    static let border = Color(Palette.neutral800)

    // MARK: Text and icons

    static let textPrimary = Color(Palette.neutral50)
    static let textSecondary = Color(Palette.neutral300)
    static let textTertiary = Color(Palette.neutral500)
    /// Inactive page dots and other quiet indicators.
    static let indicator = Color(Palette.neutral600)

    // MARK: Brand and growth

    /// You improved: gains, the +%, a target you beat. Never decorative text.
    static let accent = Color(Palette.green300)
    /// Tinted fills behind accent content.
    static let accentMuted = Color(Palette.green900)

    /// The soft green glow falling from the top of the screen, measured from the onboarding
    /// reference (design/references/006): lightness fades evenly from the glow colour at the top
    /// to the canvas just past half the screen, mixed in OKLab so it never turns muddy.
    static func glow(fadesOutAt end: Double = 0.52) -> LinearGradient {
        let steps = 12
        var stops = (0...steps).map { index -> Gradient.Stop in
            let t = Double(index) / Double(steps)
            return .init(color: Palette.green600.mixed(with: Palette.neutral950, amount: t), location: t * end)
        }
        stops.append(.init(color: canvas, location: 1))
        return LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
    }
}

/// The type scale, named by use. Geist throughout; sizes follow Dynamic Type.
enum TypeScale {
    enum Weight: String {
        case regular = "Geist-Regular"
        case semibold = "Geist-SemiBold"
        case bold = "Geist-Bold"
        case extraBold = "Geist-ExtraBold"
    }

    /// The Tracko wordmark on the welcome page.
    static let wordmark = Font.custom(Weight.extraBold.rawValue, size: 52, relativeTo: .largeTitle)
    /// "Welcome to", above the wordmark.
    static let intro = Font.custom(Weight.semibold.rawValue, size: 24, relativeTo: .title2)
    /// Page headlines: two short lines.
    static let headline = Font.custom(Weight.bold.rawValue, size: 34, relativeTo: .largeTitle)
    /// Sublines and body copy.
    static let body = Font.custom(Weight.regular.rawValue, size: 17, relativeTo: .body)
    /// Button labels.
    static let button = Font.custom(Weight.semibold.rawValue, size: 17, relativeTo: .headline)

    /// Letter-spacing for large text, as a share of the font size: big type looks better a
    /// little tighter.
    static let headlineTracking = -0.02
    static let wordmarkTracking = -0.035

    /// Text drawn inside an illustration, such as the giant phone's screen. Fixed size: it
    /// scales with the picture, not with Dynamic Type, and the illustration carries an
    /// accessibility label instead.
    static func illustration(_ weight: Weight, _ size: CGFloat) -> Font {
        Font.custom(weight.rawValue, fixedSize: size)
    }
}

enum Space {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    /// Side margin for text.
    static let gutter: CGFloat = 24
}

enum Radius {
    static let small: CGFloat = 8
    static let card: CGFloat = 14
}

enum Motion {
    /// Things that settle into place.
    static let settle = Animation.spring(duration: 0.55, bounce: 0.22)
    /// UI feedback: presses, selections, page dots.
    static let snappy = Animation.snappy(duration: 0.25)
    /// Bars and curves that grow. Long and soft.
    static let grow = Animation.spring(duration: 1.2, bounce: 0.05)
    /// Crossfades, and the Reduce Motion stand-in for movement.
    static let fade = Animation.easeInOut(duration: 0.35)
    /// An expression swap on a character: fast enough to read as a cut.
    static let faceSwap = Animation.easeOut(duration: 0.12)
}
