public enum Direction: CaseIterable {
    case left, right, up, down
}

/// Which action a key press maps to.
public enum Variant {
    case normal   // Win+Arrow
    case display  // Win+Shift+Left/Right: move to the adjacent display
    case half     // Win+Alt+Up/Down: top/bottom half
}

public enum SnapAction: Equatable {
    case snap(Zone, display: Int)
    case restore
    case minimize
    case none
}

/// The Windows 11 Win+Arrow state machine, as a pure function of the window's current zone.
public enum SnapRules {
    /// `display` is the index of the window's display and `displayCount` how many there are, both left to right.
    public static func action(_ direction: Direction, variant: Variant, zone: Zone, display di: Int,
                              displayCount count: Int, downMinimizes: Bool) -> SnapAction {
        switch variant {
        case .normal: return normal(direction, zone: zone, display: di, count: count, downMinimizes: downMinimizes)
        case .display: return displayMove(direction, zone: zone, display: di, count: count)
        case .half: return .snap(direction == .up ? .top : .bottom, display: di)
        }
    }

    private static func normal(_ direction: Direction, zone: Zone, display di: Int, count: Int,
                               downMinimizes: Bool) -> SnapAction {
        switch direction {
        case .left:
            switch zone {
            case .other, .maximized: return .snap(.left, display: di)
            case .top: return .snap(.topLeft, display: di)
            case .bottom: return .snap(.bottomLeft, display: di)
            case .right: return .restore
            case .topRight: return .snap(.topLeft, display: di)
            case .bottomRight: return .snap(.bottomLeft, display: di)
            case .left, .topLeft, .bottomLeft:
                // Already against the left edge: continue onto the display on the left,
                // wrapping around to the rightmost one.
                return count > 1 ? .snap(zone.mirrored, display: (di - 1 + count) % count) : .none
            }
        case .right:
            switch zone {
            case .other, .maximized: return .snap(.right, display: di)
            case .top: return .snap(.topRight, display: di)
            case .bottom: return .snap(.bottomRight, display: di)
            case .left: return .restore
            case .topLeft: return .snap(.topRight, display: di)
            case .bottomLeft: return .snap(.bottomRight, display: di)
            case .right, .topRight, .bottomRight:
                return count > 1 ? .snap(zone.mirrored, display: (di + 1) % count) : .none
            }
        case .up:
            switch zone {
            case .other, .topLeft, .topRight: return .snap(.maximized, display: di)
            case .top: return .none // nothing above to move to
            case .bottom: return .restore
            case .left: return .snap(.topLeft, display: di)
            case .right: return .snap(.topRight, display: di)
            case .bottomLeft: return .snap(.left, display: di)
            case .bottomRight: return .snap(.right, display: di)
            case .maximized: return .snap(.top, display: di)
            }
        case .down:
            switch zone {
            case .maximized, .top: return .restore
            case .left: return .snap(.bottomLeft, display: di)
            case .right: return .snap(.bottomRight, display: di)
            case .topLeft: return .snap(.left, display: di)
            case .topRight: return .snap(.right, display: di)
            case .bottom, .bottomLeft, .bottomRight, .other: return downMinimizes ? .minimize : .none
            }
        }
    }

    /// Shift+Left/Right: same slot (or proportional position) on the neighbouring display, wrapping around.
    private static func displayMove(_ direction: Direction, zone: Zone, display di: Int, count: Int) -> SnapAction {
        guard count > 1, direction == .left || direction == .right else { return .none }
        return .snap(zone, display: (direction == .left ? di - 1 + count : di + 1) % count)
    }
}
