import AppKit
import CoreGraphics

/// Intercepts ⌃⌘D system-wide via a CGEvent tap, swallowing the event so
/// the built-in dictionary popover never fires, and invokes `onHotkey`
/// instead. Requires Accessibility access; `start()` is a no-op (returning
/// false) until that's granted.
final class HotkeyManager {
    /// kVK_ANSI_D — virtual key codes identify the physical key position,
    /// so this matches the system shortcut on any keyboard layout.
    private static let keyD: Int64 = 2

    var onHotkey: (() -> Void)?

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var isRunning: Bool { tap != nil }

    @discardableResult
    func start() -> Bool {
        guard tap == nil else { return true }
        guard UserDefaults.standard.interceptSystemShortcut else { return false }

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
            return manager.handle(type: type, event: event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            NSLog("Define: failed to create event tap (missing Accessibility access?)")
            return false
        }

        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        tap = nil
        runLoopSource = nil
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // The system disables taps that stall or when the machine sleeps;
        // re-enable and let this event through.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown,
              event.getIntegerValueField(.keyboardEventKeycode) == Self.keyD,
              event.flags.contains([.maskCommand, .maskControl]),
              !event.flags.contains(.maskAlternate),
              !event.flags.contains(.maskShift)
        else {
            return Unmanaged.passUnretained(event)
        }

        DispatchQueue.main.async { [weak self] in
            self?.onHotkey?()
        }
        // Swallow the event so the built-in dictionary popover doesn't appear.
        return nil
    }
}

extension UserDefaults {
    private static let interceptKey = "interceptSystemShortcut"

    /// Whether Define takes over ⌃⌘D. On by default; the Settings tab
    /// exposes this for users who want to keep the built-in popover.
    var interceptSystemShortcut: Bool {
        get { object(forKey: Self.interceptKey) as? Bool ?? true }
        set { set(newValue, forKey: Self.interceptKey) }
    }
}
