import AppKit
import SwiftUI

/// Wraps NSSearchField for native macOS search field appearance and focus control.
struct NativeSearchField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var focusToken: Int
    var onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit)
    }

    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField()
        searchField.placeholderString = placeholder
        searchField.target = context.coordinator
        searchField.action = #selector(Coordinator.submit)
        searchField.delegate = context.coordinator
        searchField.sendsSearchStringImmediately = true
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.widthAnchor.constraint(equalToConstant: 220).isActive = true
        context.coordinator.searchField = searchField
        return searchField
    }

    func updateNSView(_ searchField: NSSearchField, context: Context) {
        if searchField.stringValue != text {
            searchField.stringValue = text
        }
        searchField.placeholderString = placeholder
        context.coordinator.onSubmit = onSubmit

        if context.coordinator.lastFocusToken != focusToken {
            context.coordinator.lastFocusToken = focusToken
            DispatchQueue.main.async {
                searchField.window?.makeFirstResponder(searchField)
            }
        }
    }

    final class Coordinator: NSObject, NSSearchFieldDelegate {
        @Binding var text: String
        var onSubmit: () -> Void
        weak var searchField: NSSearchField?
        var lastFocusToken = 0

        init(text: Binding<String>, onSubmit: @escaping () -> Void) {
            _text = text
            self.onSubmit = onSubmit
        }

        @objc func submit() {
            text = searchField?.stringValue ?? ""
            onSubmit()
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let searchField = notification.object as? NSSearchField else { return }
            text = searchField.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                text = searchField?.stringValue ?? ""
                onSubmit()
                return true
            }
            return false
        }
    }
}
