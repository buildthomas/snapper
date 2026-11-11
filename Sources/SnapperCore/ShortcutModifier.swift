import CoreGraphics

/// Modifier combos offered in the menu. Plain Cmd+Arrow is deliberately absent (line/document
/// navigation). Option-only is offered, but it swallows word/paragraph navigation in text fields.
public enum ShortcutModifier: String, CaseIterable {
    case option
    case controlOption
    case controlCommand
    case controlOptionCommand

    public var symbols: String {
        switch self {
        case .option: return "⌥"
        case .controlOption: return "⌃⌥"
        case .controlCommand: return "⌃⌘"
        case .controlOptionCommand: return "⌃⌥⌘"
        }
    }

    public var title: String {
        switch self {
        case .option: return "Option"
        case .controlOption: return "Control + Option"
        case .controlCommand: return "Control + Command"
        case .controlOptionCommand: return "Control + Option + Command"
        }
    }

    public var flags: CGEventFlags {
        switch self {
        case .option: return .maskAlternate
        case .controlOption: return [.maskControl, .maskAlternate]
        case .controlCommand: return [.maskControl, .maskCommand]
        case .controlOptionCommand: return [.maskControl, .maskAlternate, .maskCommand]
        }
    }

    /// Modifiers for the top/bottom-half shortcut. Windows uses Win+Alt+Up/Down. On a Mac
    /// keyboard Option sits where the Windows key does and Command where Alt does, so the
    /// analogue is the base modifier plus Command (plus Shift if Command is already in use).
    public var halfFlags: CGEventFlags {
        flags.contains(.maskCommand) ? flags.union(.maskShift) : flags.union(.maskCommand)
    }

    private static let modifierMask: CGEventFlags = [.maskControl, .maskAlternate, .maskCommand, .maskShift]

    /// Which variant (if any) the held modifiers select for an arrow key. Exact match: arrow keys also
    /// carry fn/numpad flags, so only the four real modifiers are compared.
    public func variant(for direction: Direction, held: CGEventFlags) -> Variant? {
        let held = held.intersection(Self.modifierMask)
        switch direction {
        case .left, .right:
            if held == flags { return .normal }
            if held == flags.union(.maskShift) { return .display }
        case .up, .down:
            if held == flags { return .normal }
            if held == halfFlags { return .half }
        }
        return nil
    }
}
