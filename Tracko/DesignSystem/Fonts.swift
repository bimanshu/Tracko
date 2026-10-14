import CoreText
import Foundation

/// Registers the bundled Geist faces (OFL, see Fonts/Geist-OFL.txt) for this process.
/// Call once at launch, and in previews, before any view uses `TypeScale`.
enum Fonts {
    static func register() {
        for weight in [TypeScale.Weight.regular, .semibold, .bold, .extraBold] {
            let url = Bundle.main.url(forResource: weight.rawValue, withExtension: "ttf")
                ?? Bundle.main.url(forResource: weight.rawValue, withExtension: "ttf", subdirectory: "Fonts")
            guard let url else {
                assertionFailure("Missing font file \(weight.rawValue).ttf")
                continue
            }
            // Fails harmlessly when a face is already registered (previews call this repeatedly).
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
