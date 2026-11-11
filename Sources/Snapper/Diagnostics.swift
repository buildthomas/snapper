import AppKit
import ApplicationServices
import ServiceManagement
import SnapperCore

/// The `--diagnostics` report: everything worth pasting into a bug report.
enum Diagnostics {
    static func report() -> String {
        let os = ProcessInfo.processInfo.operatingSystemVersionString
        var lines = [
            "Snapper \(snapperVersion)",
            "macOS: \(os)",
            "architecture: \(arch())",
            "bundle: \(Bundle.main.bundleURL.path)",
            "bundle id: \(Bundle.main.bundleIdentifier ?? "(none; not running from an installed .app?)")",
            "Accessibility: \(AXIsProcessTrusted() ? "granted" : "NOT granted")",
            "shortcut modifier: \(Settings.shared.modifier.title) (\(Settings.shared.modifier.symbols))",
            "down arrow minimizes: \(Settings.shared.downMinimizes)",
            "start at login: \(loginStatus())",
            "log: \(Log.file.path)",
            "displays (left to right, usable area in points):",
        ]
        for (i, screen) in NSScreen.screens.sorted(by: { $0.frame.minX < $1.frame.minX }).enumerated() {
            let f = screen.visibleFrame
            lines.append("  \(i): \(Int(f.width))x\(Int(f.height)) at (\(Int(f.minX)), \(Int(f.minY))), scale \(screen.backingScaleFactor)")
        }
        return lines.joined(separator: "\n")
    }

    private static func loginStatus() -> String {
        switch SMAppService.mainApp.status {
        case .enabled: return "on"
        case .notRegistered: return "off"
        case .requiresApproval: return "needs approval in System Settings > General > Login Items"
        case .notFound: return "not found (not running from an installed .app?)"
        @unknown default: return "unknown"
        }
    }

    private static func arch() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        return withUnsafeBytes(of: &sysinfo.machine) { raw in
            String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
        }
    }
}
