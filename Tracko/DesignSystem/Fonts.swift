import CoreText
import UIKit

/// Registers every font bundled with the app (DesignSystem/Fonts: OFL families, plus Satoshi when
/// scripts/fetch-fonts.sh has fetched it) for this process. Call once at launch, and in previews,
/// before any view uses `TypeScale`.
enum Fonts {
    static func register() {
        let urls = ["ttf", "otf"].flatMap { Bundle.main.urls(forResourcesWithExtension: $0, subdirectory: nil) ?? [] }
        for url in urls {
            // Fails harmlessly when a face is already registered (previews call this repeatedly).
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    /// Whether a family's files are in the app (Satoshi isn't, until it's fetched).
    static func isAvailable(_ family: TypeScale.Family) -> Bool {
        UIFont(name: family.fontName(.regular), size: 12) != nil
    }
}
