import SwiftUI
import UIKit

/// One line of the workout note. It behaves like a line in Notes: Return starts the next line,
/// Delete on an empty line goes back to the one above, and pasting several lines splits them.
/// UIKit underneath, because SwiftUI's text field can't report Delete on an empty line.
struct NoteLineField: UIViewRepresentable {
    @Binding var text: String
    let id: NoteText.ID
    @Binding var focusedLine: NoteText.ID?
    var placeholder: String
    var weight: TypeScale.Weight = .regular
    var onReturn: () -> Void
    var onDeleteEmpty: () -> Void
    var onPasteLines: ([String]) -> Void

    func makeUIView(context: Context) -> LineTextField {
        let field = LineTextField()
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)
        field.adjustsFontForContentSizeCategory = true
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.smartQuotesType = .no
        field.smartDashesType = .no
        field.autocapitalizationType = .sentences
        field.returnKeyType = .default
        field.keyboardAppearance = .dark
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return field
    }

    func updateUIView(_ field: LineTextField, context: Context) {
        context.coordinator.parent = self
        if field.text != text { field.text = text }
        let font = TypeScale.noteFont(weight, legibility: context.environment.legibilityWeight)
        if field.font != font { field.font = font }
        field.textColor = UIColor(Theme.textPrimary)
        field.tintColor = UIColor(Theme.accent)
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor(Theme.textTertiary), .font: font]
        )
        field.onDeleteWhenEmpty = { context.coordinator.parent.onDeleteEmpty() }
        if focusedLine == id, !field.isFirstResponder {
            DispatchQueue.main.async { field.becomeFirstResponder() }
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: LineTextField, context: Context) -> CGSize? {
        let height = max(44, ceil(uiView.intrinsicContentSize.height))
        return CGSize(width: proposal.width ?? 200, height: height)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: NoteLineField

        init(parent: NoteLineField) {
            self.parent = parent
        }

        @objc func textChanged(_ field: UITextField) {
            parent.text = field.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            if parent.focusedLine != parent.id { parent.focusedLine = parent.id }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            // Only when focus left the note, not when it moved to another line.
            if parent.focusedLine == parent.id { parent.focusedLine = nil }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onReturn()
            return false
        }

        func textField(
            _ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String
        ) -> Bool {
            guard string.contains(where: \.isNewline) else { return true }
            let current = (textField.text ?? "") as NSString
            let combined = current.replacingCharacters(in: range, with: string)
            parent.onPasteLines(combined.components(separatedBy: .newlines))
            return false
        }
    }
}

/// A text field that reports Delete when it's already empty.
final class LineTextField: UITextField {
    var onDeleteWhenEmpty: (() -> Void)?

    override func deleteBackward() {
        if (text ?? "").isEmpty {
            onDeleteWhenEmpty?()
        } else {
            super.deleteBackward()
        }
    }
}
