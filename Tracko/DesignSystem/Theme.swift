import SwiftUI

// Design tokens (skill §9). Use these, never raw values, in every view.
// Each signal colour has one meaning and is never decorative.
// Red is reserved for muscles: never for losses or bodyweight.

enum Theme {
    // MARK: The scoreboard (dark)

    /// App background.
    static let ink = Color(hex: 0x16171B)
    /// Cards.
    static let slab = Color(hex: 0x1E2027)
    /// Cards on cards.
    static let slabRaised = Color(hex: 0x262931)
    /// Borders and dividers.
    static let hairline = Color(hex: 0x2E313A)
    static let chalk = Color(hex: 0xEDEEF0)
    static let chalkMuted = Color(hex: 0x9AA0A8)
    static let chalkDim = Color(hex: 0x6B7079)

    // MARK: The notes page (light)

    static let paper = Color(hex: 0xFAF8F2)
    static let pencil = Color(hex: 0x26262A)
    static let highlighter = Color(hex: 0xFCE8A6)

    // MARK: Signals

    /// You improved.
    static let gain = Color(hex: 0x3DBA6E)
    /// What to do next; the primary button.
    static let target = Color(hex: 0xF2C230)
    /// Muscles you trained. Never "bad".
    static let muscle = Color(hex: 0xE5484D)
    /// History, last time, the ghost.
    static let past = Color(hex: 0x4C8BF5)

    /// The body illustration.
    static let figure = Color(hex: 0x3A3F4B)
}

enum Space {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    /// Side margin on every screen.
    static let gutter: CGFloat = 20
}

enum Radius {
    static let chip: CGFloat = 8
    static let button: CGFloat = 14
    static let card: CGFloat = 18
}

enum Motion {
    /// Things that settle into place.
    static let settle = Animation.spring(duration: 0.55, bounce: 0.22)
    /// UI feedback: presses, selections, toggles.
    static let snappy = Animation.snappy(duration: 0.25)
    /// Bars and bodies that grow. Long and soft.
    static let grow = Animation.spring(duration: 1.2, bounce: 0.05)
    /// Crossfades, and the Reduce Motion stand-in for movement.
    static let fade = Animation.easeInOut(duration: 0.35)
}

extension Font {
    /// Scoreboard numbers and scene headlines: SF Pro Compressed Black.
    static func score(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black).width(.compressed)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
