import CoreText
import Foundation

/// Registers every font bundled with the app (DesignSystem/Fonts, all SIL OFL) for this process.
/// Call once at launch, and in previews, before any view uses `TypeScale`.
enum Fonts {
    static func register() {
        let urls = ["ttf", "otf"].flatMap { Bundle.main.urls(forResourcesWithExtension: $0, subdirectory: nil) ?? [] }
        for url in urls {
            // Fails harmlessly when a face is already registered (previews call this repeatedly).
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
