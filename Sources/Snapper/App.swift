import Cocoa
import ServiceManagement
import SnapperCore

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let windowManager = WindowManager()
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Log.info("Snapper \(snapperVersion) started")
        windowManager.downMinimizes = Settings.shared.downMinimizes

        configureStatusItem()
        enableLaunchAtLoginOnFirstRun()

        KeyTap.shared.modifier = Settings.shared.modifier
        KeyTap.shared.handler = { [weak self] direction, variant in
            self?.windowManager.handle(direction, variant: variant)
        }

        // The event tap can only be created once Accessibility is granted, so keep retrying
        // until it is: no relaunch needed after the user flips the switch.
        if KeyTap.shared.start() {
            Log.info("shortcut keys active")
        } else {
            Log.info("waiting for Accessibility access")
            requestAccessibility()
            permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] timer in
                if KeyTap.shared.start() {
                    Log.info("Accessibility granted; shortcut keys active")
                    timer.invalidate()
                    self?.permissionTimer = nil
                }
            }
        }
    }

    // MARK: - Status item & menu

    private func configureStatusItem() {
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "rectangle.split.2x2", accessibilityDescription: "Snapper")
            image?.isTemplate = true
            button.image = image
            if image == nil { button.title = "⊞" }
        }
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    /// Rebuilt on every open so permission, login-item and shortcut state are always current.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        if !AXIsProcessTrusted() {
            let item = NSMenuItem(title: "Grant Accessibility Access…", action: #selector(openAccessibilitySettings), keyEquivalent: "")
            item.target = self
            menu.addItem(item)
            let hint = NSMenuItem(title: "Required to move other apps' windows", action: nil, keyEquivalent: "")
            hint.isEnabled = false
            menu.addItem(hint)
            menu.addItem(.separator())
        }

        let m = Settings.shared.modifier.symbols
        let half = Settings.shared.modifier.halfFlags.contains(.maskShift) ? "\(m)⇧" : "\(m)⌘"
        for (keys, label) in [
            ("\(m)←", "Snap left / restore"),
            ("\(m)→", "Snap right / restore"),
            ("\(m)↑", "Maximize / top half / snap up"),
            ("\(m)↓", "Restore / snap down / minimize"),
            ("\(half)↑", "Top half"),
            ("\(half)↓", "Bottom half"),
            ("\(m)⇧←", "Move to display on left"),
            ("\(m)⇧→", "Move to display on right"),
        ] {
            let item = NSMenuItem(title: "\(keys)   \(label)", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }
        menu.addItem(.separator())

        let shortcutMenu = NSMenu()
        for option in ShortcutModifier.allCases {
            let item = NSMenuItem(title: "\(option.symbols)  \(option.title)", action: #selector(selectModifier(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = option.rawValue
            item.state = option == Settings.shared.modifier ? .on : .off
            shortcutMenu.addItem(item)
        }
        let shortcutItem = NSMenuItem(title: "Shortcut Keys", action: nil, keyEquivalent: "")
        shortcutItem.submenu = shortcutMenu
        menu.addItem(shortcutItem)

        let minimize = NSMenuItem(title: "Down Arrow Minimizes Window", action: #selector(toggleDownMinimizes), keyEquivalent: "")
        minimize.target = self
        minimize.state = Settings.shared.downMinimizes ? .on : .off
        menu.addItem(minimize)

        let login = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Snapper", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
    }

    // MARK: - Actions

    @objc private func selectModifier(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let option = ShortcutModifier(rawValue: raw) else { return }
        Settings.shared.modifier = option
        KeyTap.shared.modifier = option
    }

    @objc private func toggleDownMinimizes() {
        Settings.shared.downMinimizes.toggle()
        windowManager.downMinimizes = Settings.shared.downMinimizes
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            Log.error("login item change failed: \(error.localizedDescription)")
            let alert = NSAlert()
            alert.messageText = "Couldn't change the login item"
            alert.informativeText = "\(error.localizedDescription)\n\nMake sure Snapper is in your Applications folder."
            alert.runModal()
        }
    }

    @objc private func openAccessibilitySettings() {
        requestAccessibility()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func requestAccessibility() {
        // Literal key: kAXTrustedCheckOptionPrompt is a mutable C global and trips strict concurrency.
        _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }

    private func enableLaunchAtLoginOnFirstRun() {
        guard !Settings.shared.loginItemConfigured else { return }
        Settings.shared.loginItemConfigured = true
        do {
            try SMAppService.mainApp.register()
        } catch {
            Log.error("registering the login item failed: \(error.localizedDescription)")
        }
    }
}
