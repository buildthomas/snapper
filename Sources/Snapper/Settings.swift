import Foundation
import SnapperCore

/// UserDefaults-backed settings (domain com.thoeksema.Snapper). Inspect with `defaults read com.thoeksema.Snapper`.
final class Settings {
    static let shared = Settings()
    private let d = UserDefaults.standard

    private init() {
        d.register(defaults: [
            "shortcutModifier": ShortcutModifier.controlOption.rawValue,
            "downMinimizes": true,
            "loginItemConfigured": false,
        ])
    }

    var modifier: ShortcutModifier {
        get { ShortcutModifier(rawValue: d.string(forKey: "shortcutModifier") ?? "") ?? .controlOption }
        set { d.set(newValue.rawValue, forKey: "shortcutModifier") }
    }
    var downMinimizes: Bool { get { d.bool(forKey: "downMinimizes") } set { d.set(newValue, forKey: "downMinimizes") } }
    /// Whether the "start at login" default has been chosen; after that the menu toggle is the source of truth.
    var loginItemConfigured: Bool { get { d.bool(forKey: "loginItemConfigured") } set { d.set(newValue, forKey: "loginItemConfigured") } }
}
