import Carbon.HIToolbox
import Cocoa
import SnapperCore

extension Direction {
    var keyCode: Int64 {
        switch self {
        case .left: return Int64(kVK_LeftArrow)
        case .right: return Int64(kVK_RightArrow)
        case .up: return Int64(kVK_UpArrow)
        case .down: return Int64(kVK_DownArrow)
        }
    }
}

/// Global hotkeys via a session event tap. A tap can consume the key so the focused app never
/// sees it, and needs only the Accessibility permission we already require.
final class KeyTap {
    static let shared = KeyTap()

    /// Called on the main thread.
    var handler: ((Direction, Variant) -> Void)?
    var modifier: ShortcutModifier = .controlOption

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    /// Key-ups for keys whose key-down we consumed, so the app never sees an orphan key-up.
    private var consumedKeyUps = Set<Int64>()

    var isRunning: Bool { tap != nil }

    /// Fails (returns false) until Accessibility access has been granted.
    @discardableResult
    func start() -> Bool {
        if tap != nil { return true }
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, _ in KeyTap.shared.handle(type, event) },
            userInfo: nil)
        else { return false }

        // Don't let one hung app stall every keypress for the default 6 seconds.
        AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), 0.25)

        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.tap = tap
        self.source = source
        return true
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        let pass = Unmanaged.passUnretained(event)

        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return pass

        case .keyUp:
            let code = event.getIntegerValueField(.keyboardEventKeycode)
            return consumedKeyUps.remove(code) != nil ? nil : pass

        case .keyDown:
            let code = event.getIntegerValueField(.keyboardEventKeycode)
            guard let direction = Direction.allCases.first(where: { $0.keyCode == code }) else { return pass }
            guard let variant = modifier.variant(for: direction, held: event.flags) else { return pass }

            consumedKeyUps.insert(code)
            // Holding the keys down must not re-snap repeatedly, but must not leak to the app either.
            if event.getIntegerValueField(.keyboardEventAutorepeat) == 0 {
                DispatchQueue.main.async { self.handler?(direction, variant) }
            }
            return nil

        default:
            return pass
        }
    }
}
