import CoreGraphics

public enum Geometry {
    /// Index of the display `frame` overlaps most, or the nearest one when it is entirely off-screen.
    public static func displayIndex(for frame: CGRect, in displays: [CGRect]) -> Int {
        var best = 0, bestArea: CGFloat = -1
        for (i, display) in displays.enumerated() {
            let overlap = display.intersection(frame)
            let area = overlap.isNull ? 0 : overlap.width * overlap.height
            if area > bestArea { best = i; bestArea = area }
        }
        if bestArea > 0 { return best }
        let center = CGPoint(x: frame.midX, y: frame.midY)
        return displays.enumerated().min {
            hypot($0.element.midX - center.x, $0.element.midY - center.y)
                < hypot($1.element.midX - center.x, $1.element.midY - center.y)
        }?.offset ?? 0
    }

    /// Where Restore puts a window that has no remembered frame: 60% of the area, centred.
    public static func defaultFrame(in area: CGRect) -> CGRect {
        let w = (area.width * 0.6).rounded(), h = (area.height * 0.6).rounded()
        return CGRect(x: area.minX + ((area.width - w) / 2).rounded(),
                      y: area.minY + ((area.height - h) / 2).rounded(), width: w, height: h)
    }

    /// Keeps a frame's relative size and position when moving it from one display's area to another's.
    public static func scale(_ r: CGRect, from a: CGRect, to b: CGRect) -> CGRect {
        let sx = b.width / a.width, sy = b.height / a.height
        let w = min(r.width * sx, b.width), h = min(r.height * sy, b.height)
        let x = min(max(b.minX + (r.minX - a.minX) * sx, b.minX), b.maxX - w)
        let y = min(max(b.minY + (r.minY - a.minY) * sy, b.minY), b.maxY - h)
        return CGRect(x: x.rounded(), y: y.rounded(), width: w.rounded(), height: h.rounded())
    }
}

public extension CGRect {
    func isClose(to other: CGRect, tolerance: CGFloat) -> Bool {
        abs(minX - other.minX) <= tolerance && abs(minY - other.minY) <= tolerance
            && abs(width - other.width) <= tolerance && abs(height - other.height) <= tolerance
    }
}
