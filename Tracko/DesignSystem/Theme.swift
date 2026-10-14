import SwiftUI
import UIKit

// Design tokens (skill §9). Views use `Theme`, `TypeScale`, `Space`, `Radius` and `Motion`,
// never raw values. Keep the OKLCH numbers identical to design/tools/palette.py, which checks
// their gamut and contrast.

/// Primitives: ramps named by hue and step. Views never use these directly; `Theme` names
/// what each one is for.
enum Palette {
    // Neutral ramp: a hint of the brand hue, chroma kept low. Steps sit closer at the light end,
    // where text lives; lightness is set so every pair in `Theme` passes WCAG 2 and APCA.
    static let neutral950 = OKLCH(0.090, 0.004, 160)
    static let neutral850 = OKLCH(0.225, 0.010, 160)
    static let neutral800 = OKLCH(0.290, 0.012, 160)
    static let neutral600 = OKLCH(0.570, 0.012, 160)
    static let neutral400 = OKLCH(0.770, 0.012, 160)
    static let neutral300 = OKLCH(0.850, 0.010, 160)
    static let neutral100 = OKLCH(0.920, 0.008, 160)
    static let neutral50 = OKLCH(0.975, 0.005, 160)

    // Green ramp: the brand, one hue end to end. The glow and the accent are the only steps in use.
    static let green600 = OKLCH(0.500, 0.170, 152)
    static let green300 = OKLCH(0.850, 0.235, 152)

    static let all = [
        neutral950, neutral850, neutral800, neutral600, neutral400, neutral300, neutral100, neutral50,
        green600, green300,
    ]
}

/// A role's primitive in the standard appearance and with Increase Contrast on.
struct Role {
    let standard: OKLCH
    let increased: OKLCH

    init(_ standard: OKLCH, increased: OKLCH? = nil) {
        self.standard = standard
        self.increased = increased ?? standard
    }

    /// Resolves per view, so it follows the Increase Contrast setting live.
    var color: Color {
        let standardColor = self.standard.uiColor
        let increasedColor = self.increased.uiColor
        return Color(uiColor: UIColor { traits in
            traits.accessibilityContrast == .high ? increasedColor : standardColor
        })
    }
}

/// Semantic tokens: what each colour is for. Names follow `{role}{Variant}`: bg, text, border,
/// fill, accent. Green means growth, and is the brand. With Increase Contrast on, muted roles
/// move at least 15 points of lightness further from the page.
enum Theme {
    enum Roles {
        static let bgPage = Role(Palette.neutral950)
        static let bgRaised = Role(Palette.neutral850)
        static let bgInverse = Role(Palette.neutral50)
        static let border = Role(Palette.neutral800, increased: Palette.neutral600)
        static let textPrimary = Role(Palette.neutral50)
        static let textSecondary = Role(Palette.neutral300, increased: Palette.neutral50)
        static let textTertiary = Role(Palette.neutral400, increased: Palette.neutral100)
        static let textInverse = Role(Palette.neutral950)
        static let fillSubtle = Role(Palette.neutral600, increased: Palette.neutral400)
        static let fillStrong = Role(Palette.neutral300, increased: Palette.neutral50)
        static let accent = Role(Palette.green300)
    }

    // MARK: Backgrounds

    /// The page: near-black, so the glow and the 3D heroes carry the light.
    static let bgPage = Roles.bgPage.color
    /// Raised parts: set tiles, tracks behind bars, secondary buttons.
    static let bgRaised = Roles.bgRaised.color
    /// The one light surface: the primary button.
    static let bgInverse = Roles.bgInverse.color

    // MARK: Borders, text and fills

    /// Dividers and outlines that only give structure.
    static let border = Roles.border.color
    static let textPrimary = Roles.textPrimary.color
    static let textSecondary = Roles.textSecondary.color
    static let textTertiary = Roles.textTertiary.color
    /// Text on `bgInverse` and on accent fills.
    static let textInverse = Roles.textInverse.color
    /// Quiet indicators: inactive page dots.
    static let fillSubtle = Roles.fillSubtle.color
    /// Neutral bars and markers.
    static let fillStrong = Roles.fillStrong.color

    // MARK: Brand and growth

    /// You improved: gains, the +%, a target you beat. Never decorative text.
    static let accent = Roles.accent.color

    /// The soft green glow falling from the top of the screen, measured from the onboarding
    /// reference (design/references/006): lightness fades evenly from the glow colour at the top
    /// to the page just past half the screen, mixed in OKLab so it never turns muddy.
    static func glow(fadesOutAt end: Double = 0.52) -> LinearGradient {
        let steps = 12
        var stops = (0...steps).map { index -> Gradient.Stop in
            let t = Double(index) / Double(steps)
            return .init(color: Palette.green600.mixed(with: Palette.neutral950, amount: t), location: t * end)
        }
        stops.append(.init(color: bgPage, location: 1))
        return LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
    }
}

/// The type scale, named by use. Geist throughout; sizes follow Dynamic Type, and the Bold Text
/// setting steps each face up one weight.
enum TypeScale {
    enum Weight: String {
        case regular = "Geist-Regular"
        case semibold = "Geist-SemiBold"
        case bold = "Geist-Bold"
        case extraBold = "Geist-ExtraBold"

        /// One step heavier, for Bold Text.
        var bolder: Weight {
            switch self {
            case .regular: return .semibold
            case .semibold: return .bold
            case .bold, .extraBold: return .extraBold
            }
        }

        func resolved(_ legibility: LegibilityWeight?) -> Weight {
            legibility == .bold ? bolder : self
        }
    }

    // Line heights are multiples of the font size: display text sits tight, reading text loose.

    /// Page headlines: two short lines, balanced, at 1.1.
    static let headline = BalancedText.Style(
        weight: .bold, boldWeight: .extraBold, size: 34, textStyle: .largeTitle, lineHeight: 1.1, tracking: -0.02
    )
    /// Sublines and body copy, at 1.45.
    static let body = BalancedText.Style(
        weight: .regular, boldWeight: .semibold, size: 17, textStyle: .body, lineHeight: 1.45
    )

    /// The Tracko wordmark on the welcome page (already the heaviest face), tightened 3.5%.
    static let wordmark = Font.custom(Weight.extraBold.rawValue, size: 52, relativeTo: .largeTitle)
    static let wordmarkTracking = -0.035

    /// "Welcome to", above the wordmark.
    static func intro(_ legibility: LegibilityWeight?) -> Font {
        .custom(Weight.semibold.resolved(legibility).rawValue, size: 24, relativeTo: .title2)
    }

    /// Button labels.
    static func button(_ legibility: LegibilityWeight?) -> Font {
        .custom(Weight.semibold.resolved(legibility).rawValue, size: 17, relativeTo: .headline)
    }

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
}

enum Motion {
    /// Things that settle into place.
    static let settle = Animation.spring(duration: 0.55, bounce: 0.22)
    /// UI feedback: page dots, small state changes.
    static let snappy = Animation.snappy(duration: 0.25)
    /// Press feedback on buttons: quick and eased out.
    static let press = Animation.easeOut(duration: 0.15)
    /// A staged entrance step (staggered 100 ms apart by `.entrance(_:)`).
    static let enter = Animation.easeOut(duration: 0.45)
    /// Bars and curves that grow. Long and soft.
    static let grow = Animation.spring(duration: 1.2, bounce: 0.05)
    /// Crossfades, and the Reduce Motion stand-in for movement.
    static let fade = Animation.easeInOut(duration: 0.35)
    /// An expression swap on a character: fast enough to read as a cut.
    static let faceSwap = Animation.easeOut(duration: 0.12)
}
