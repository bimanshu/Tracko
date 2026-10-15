import SwiftUI
import UIKit

/// Display text with the typography SwiftUI can't do on iOS 17:
/// - a set line height (headlines at 1.1, not the font's own 1.3),
/// - balanced line breaks, like CSS `text-wrap: balance`: the narrowest width that keeps the
///   same number of lines, so two-line headlines split evenly and no line ends in one word,
/// - letter-spacing in em,
/// - Dynamic Type (it scales with the text style) and Bold Text (it steps up a weight).
/// Backed by a UILabel, which VoiceOver reads like any text.
struct BalancedText: UIViewRepresentable {
    struct Style {
        var weight: TypeScale.Weight
        /// The weight used when Bold Text is on.
        var boldWeight: TypeScale.Weight
        var size: CGFloat
        var textStyle: UIFont.TextStyle
        /// Line height as a multiple of the font size.
        var lineHeight: CGFloat
        /// Letter-spacing as a share of the font size.
        var tracking: CGFloat = 0
    }

    let text: String
    let style: Style
    var color: Color = Theme.textPrimary
    var alignment: NSTextAlignment = .center
    var isHeader = false
    /// The typeface, read as the view is made, so a change of `TypeScale.family` redraws it.
    let family = TypeScale.family

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        label.attributedText = attributedText(in: context.environment)
        label.accessibilityTraits = isHeader ? .header : .staticText
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize? {
        let string = attributedText(in: context.environment)
        guard let available = proposal.width, available.isFinite else {
            // Ideal size: one line.
            let line = Self.bounds(string, width: .greatestFiniteMagnitude)
            return CGSize(width: ceil(line.width), height: ceil(line.height))
        }
        let height = Self.bounds(string, width: available).height
        // Balance: shrink the width for as long as the text keeps the same number of lines.
        var low = available / 2
        var high = available
        for _ in 0..<14 {
            let middle = (low + high) / 2
            if Self.bounds(string, width: middle).height <= height + 0.5 {
                high = middle
            } else {
                low = middle
            }
        }
        return CGSize(width: min(ceil(high) + 1, available), height: ceil(height))
    }

    private static func bounds(_ string: NSAttributedString, width: CGFloat) -> CGSize {
        string.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size
    }

    private func attributedText(in environment: EnvironmentValues) -> NSAttributedString {
        let weight = environment.legibilityWeight == .bold ? style.boldWeight : style.weight
        let base = UIFont(name: family.fontName(weight), size: style.size) ?? .systemFont(ofSize: style.size)
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(environment.dynamicTypeSize))
        let font = UIFontMetrics(forTextStyle: style.textStyle).scaledFont(for: base, compatibleWith: traits)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.minimumLineHeight = font.pointSize * style.lineHeight
        paragraph.maximumLineHeight = font.pointSize * style.lineHeight

        return NSAttributedString(string: text, attributes: [
            .font: font,
            .paragraphStyle: paragraph,
            .kern: font.pointSize * style.tracking,
            .foregroundColor: UIColor(color),
        ])
    }
}
