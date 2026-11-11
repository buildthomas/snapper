import Cocoa
import ApplicationServices
import SnapperCore

/// Implements the Windows 11 Win+Arrow state machine on top of the Accessibility API.
final class WindowManager {
    private let tolerance: CGFloat = 20

    /// Frame before the first snap, so Restore can put the window back.
    private var restoreFrames: [CFHashCode: CGRect] = [:]
    /// What we last applied, and the frame the app actually settled on. Apps with minimum
    /// sizes can't always hit the exact rect, so geometry alone would misdetect the zone.
    private var applied: [CFHashCode: (zone: Zone, frame: CGRect)] = [:]

    var downMinimizes = true

    // MARK: - Entry point

    func handle(_ direction: Direction, variant: Variant) {
        guard let window = focusedWindow() else { return }
        if bool(window, "AXFullScreen") == true { return }
        guard let current = frame(of: window) else { return }

        let displays = displayFrames()
        guard !displays.isEmpty else { return }
        let di = Geometry.displayIndex(for: current, in: displays)
        let key = CFHash(window)
        let zone = zone(for: key, frame: current, display: displays[di])

        if applied.count > 500 { applied.removeAll() }
        if restoreFrames.count > 500 { restoreFrames.removeAll() }

        let action = SnapRules.action(direction, variant: variant, zone: zone, display: di,
                                      displayCount: displays.count, downMinimizes: downMinimizes)

        withEnhancedUIDisabled(for: window) {
            perform(action, on: window, key: key, current: current, zone: zone,
                    from: di, displays: displays)
        }
    }

    // MARK: - Applying

    private func perform(_ action: SnapAction, on window: AXUIElement, key: CFHashCode, current: CGRect,
                         zone: Zone, from di: Int, displays: [CGRect]) {
        switch action {
        case .none:
            return

        case .minimize:
            AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanTrue)

        case .restore:
            let area = displays[di]
            let target = restoreFrames.removeValue(forKey: key) ?? Geometry.defaultFrame(in: area)
            setFrame(window, target)
            applied[key] = (.other, frame(of: window) ?? target)

        case .snap(var newZone, let target):
            let area = displays[target]

            // Remember the free-floating frame before the first snap.
            if zone == .other { restoreFrames[key] = current }
            if target != di, let saved = restoreFrames[key] {
                restoreFrames[key] = Geometry.scale(saved, from: displays[di], to: area)
            }

            let destination: CGRect
            if let rect = newZone.rect(in: area) {
                destination = rect
            } else {
                // Free-floating window moved across displays: keep its relative placement.
                newZone = .other
                destination = Geometry.scale(current, from: displays[di], to: area)
            }
            setFrame(window, destination)
            applied[key] = (newZone, frame(of: window) ?? destination)
        }
    }

    // MARK: - Zone detection

    private func zone(for key: CFHashCode, frame: CGRect, display: CGRect) -> Zone {
        if let record = applied[key], frame.isClose(to: record.frame, tolerance: 4) {
            return record.zone
        }
        for zone in Zone.snapped {
            if let rect = zone.rect(in: display), frame.isClose(to: rect, tolerance: tolerance) {
                return zone
            }
        }
        return .other
    }

    // MARK: - Geometry

    /// Usable area (excluding menu bar and Dock) of every display in AX coordinates, left to right.
    private func displayFrames() -> [CGRect] {
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        return NSScreen.screens
            .map { screen -> CGRect in
                let v = screen.visibleFrame
                return CGRect(x: v.minX, y: primaryHeight - v.maxY, width: v.width, height: v.height)
            }
            .sorted { $0.minX < $1.minX }
    }

    // MARK: - Accessibility helpers

    private func focusedWindow() -> AXUIElement? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier
        else { return nil }
        let element = AXUIElementCreateApplication(app.processIdentifier)
        for attribute in [kAXFocusedWindowAttribute, kAXMainWindowAttribute] {
            var value: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
               let value, CFGetTypeID(value) == AXUIElementGetTypeID() {
                return (value as! AXUIElement)
            }
        }
        return nil
    }

    private func frame(of window: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?, sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let posRef, let sizeRef
        else { return nil }
        var origin = CGPoint.zero, size = CGSize.zero
        guard AXValueGetValue(posRef as! AXValue, .cgPoint, &origin),
              AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)
        else { return nil }
        return CGRect(origin: origin, size: size)
    }

    /// Size, position, size again: the first resize may be clamped by the old display's bounds,
    /// and the move can in turn clamp the size on the new one.
    private func setFrame(_ window: AXUIElement, _ rect: CGRect) {
        var origin = rect.origin, size = rect.size
        guard let posValue = AXValueCreate(.cgPoint, &origin),
              let sizeValue = AXValueCreate(.cgSize, &size) else { return }
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
    }

    private func bool(_ element: AXUIElement, _ attribute: String) -> Bool? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value else { return nil }
        return (value as? Bool)
    }

    /// Apps that enable AXEnhancedUserInterface (VoiceOver users, some Electron apps) animate
    /// and ignore rapid AX writes. Turn it off for the duration of the move.
    private func withEnhancedUIDisabled(for window: AXUIElement, _ body: () -> Void) {
        var pid: pid_t = 0
        AXUIElementGetPid(window, &pid)
        let app = AXUIElementCreateApplication(pid)
        let attribute = "AXEnhancedUserInterface" as CFString
        let wasOn = bool(app, "AXEnhancedUserInterface") == true
        if wasOn { AXUIElementSetAttributeValue(app, attribute, kCFBooleanFalse) }
        body()
        if wasOn { AXUIElementSetAttributeValue(app, attribute, kCFBooleanTrue) }
    }
}
