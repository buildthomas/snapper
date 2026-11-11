import CoreGraphics

/// Where a window sits within a display's usable area.
public enum Zone: Equatable {
    case maximized, left, right, top, bottom, topLeft, topRight, bottomLeft, bottomRight, other

    public static let snapped: [Zone] = [.maximized, .left, .right, .top, .bottom, .topLeft, .topRight, .bottomLeft, .bottomRight]

    /// Target rect inside `area`. All rects use AX coordinates (origin top-left, y down).
    public func rect(in area: CGRect) -> CGRect? {
        let midX = area.minX + (area.width / 2).rounded()
        let midY = area.minY + (area.height / 2).rounded()
        let halfW = midX - area.minX, halfH = midY - area.minY
        switch self {
        case .maximized: return area
        case .left: return CGRect(x: area.minX, y: area.minY, width: halfW, height: area.height)
        case .right: return CGRect(x: midX, y: area.minY, width: area.maxX - midX, height: area.height)
        case .top: return CGRect(x: area.minX, y: area.minY, width: area.width, height: halfH)
        case .bottom: return CGRect(x: area.minX, y: midY, width: area.width, height: area.maxY - midY)
        case .topLeft: return CGRect(x: area.minX, y: area.minY, width: halfW, height: halfH)
        case .topRight: return CGRect(x: midX, y: area.minY, width: area.maxX - midX, height: halfH)
        case .bottomLeft: return CGRect(x: area.minX, y: midY, width: halfW, height: area.maxY - midY)
        case .bottomRight: return CGRect(x: midX, y: midY, width: area.maxX - midX, height: area.maxY - midY)
        case .other: return nil
        }
    }

    /// The same slot on the display to the left/right (used when crossing a display edge).
    public var mirrored: Zone {
        switch self {
        case .left: return .right
        case .right: return .left
        case .topLeft: return .topRight
        case .topRight: return .topLeft
        case .bottomLeft: return .bottomRight
        case .bottomRight: return .bottomLeft
        default: return self
        }
    }
}
