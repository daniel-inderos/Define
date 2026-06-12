import AppKit
import ApplicationServices

/// Reads the text the user currently has selected in whatever app is
/// focused. Two strategies, in order:
///
/// 1. Accessibility API — clean, no side effects. Works in native apps;
///    unreliable in some Electron apps and browser views.
/// 2. Synthesized ⌘C + pasteboard read — works almost everywhere, but has
///    side effects, so the previous pasteboard contents are saved and
///    restored. Used only when the AX path returns nothing.
@MainActor
enum SelectionReader {
    static func currentSelection() -> String? {
        if let text = accessibilitySelection(), !text.isEmpty {
            return text
        }
        return pasteboardSelection()
    }

    // MARK: - Accessibility

    static func accessibilitySelection() -> String? {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            systemWide, kAXFocusedUIElementAttribute as CFString, &focusedRef
        ) == .success,
            let focusedRef,
            CFGetTypeID(focusedRef) == AXUIElementGetTypeID()
        else { return nil }
        let focused = focusedRef as! AXUIElement

        // Direct selected-text attribute first.
        var selectedRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(
            focused, kAXSelectedTextAttribute as CFString, &selectedRef
        ) == .success,
            let text = selectedRef as? String,
            !text.isEmpty {
            return text
        }

        // Some apps only expose the selection as a range; resolve it through
        // the parameterized string-for-range attribute.
        var rangeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            focused, kAXSelectedTextRangeAttribute as CFString, &rangeRef
        ) == .success, let rangeRef else { return nil }

        var stringRef: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
            focused, kAXStringForRangeParameterizedAttribute as CFString, rangeRef, &stringRef
        ) == .success, let text = stringRef as? String, !text.isEmpty else { return nil }
        return text
    }

    // MARK: - Pasteboard fallback

    private static func pasteboardSelection() -> String? {
        let pasteboard = NSPasteboard.general
        let savedChangeCount = pasteboard.changeCount
        let savedItems = snapshot(of: pasteboard)

        synthesizeCopyKeystroke()

        // Wait briefly for the focused app to service the copy. This blocks
        // the main thread for at most 300 ms, before any UI is shown.
        let deadline = Date().addingTimeInterval(0.3)
        while pasteboard.changeCount == savedChangeCount, Date() < deadline {
            Thread.sleep(forTimeInterval: 0.02)
        }

        defer {
            // Only restore if our ⌘C actually replaced something.
            if pasteboard.changeCount != savedChangeCount {
                pasteboard.clearContents()
                if !savedItems.isEmpty {
                    pasteboard.writeObjects(savedItems)
                }
            }
        }

        guard pasteboard.changeCount != savedChangeCount else { return nil }
        return pasteboard.string(forType: .string)
    }

    private static func snapshot(of pasteboard: NSPasteboard) -> [NSPasteboardItem] {
        (pasteboard.pasteboardItems ?? []).map { item in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            return copy
        }
    }

    private static func synthesizeCopyKeystroke() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyC: CGKeyCode = 8 // kVK_ANSI_C
        guard
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyC, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyC, keyDown: false)
        else { return }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
