import AppKit
import ServiceManagement
import SnapperCore

let args = CommandLine.arguments
if args.contains("--version") {
    print("Snapper \(snapperVersion)")
    exit(0)
}
if args.contains("--unregister-login") {
    try? SMAppService.mainApp.unregister()
    print("Start at login: \(SMAppService.mainApp.status == .enabled ? "still enabled" : "off")")
    exit(0)
}
if args.contains("--diagnostics") {
    _ = NSApplication.shared
    print(Diagnostics.report())
    exit(0)
}

// Single instance: two copies would both consume the shortcut keys.
if let id = Bundle.main.bundleIdentifier,
   NSRunningApplication.runningApplications(withBundleIdentifier: id).contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
    Log.info("already running; exiting")
    Log.flush()
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
