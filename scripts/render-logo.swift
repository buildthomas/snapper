// Renders docs/logo.png (1024x1024). Usage: swift scripts/render-logo.swift <output.png>
import Cocoa

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

// Rounded-square body with a diagonal gradient, like the system app icons.
let inset = size * 0.03
let body = NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
let bodyPath = NSBezierPath(roundedRect: body, xRadius: size * 0.225, yRadius: size * 0.225)
NSGradient(colors: [NSColor(srgbRed: 0.31, green: 0.76, blue: 0.98, alpha: 1),
                    NSColor(srgbRed: 0.16, green: 0.36, blue: 0.88, alpha: 1)])!
    .draw(in: bodyPath, angle: -45)

// A window frame snapped into a half plus two quarters.
let pad = size * 0.2
let line = size * 0.058
let frame = NSRect(x: pad, y: pad, width: size - 2 * pad, height: size - 2 * pad)
let gap = line * 0.9
let inner = frame.insetBy(dx: line / 2, dy: line / 2)
let midX = inner.midX, midY = inner.midY

NSColor.white.setStroke()
let outline = NSBezierPath(roundedRect: frame.insetBy(dx: line / 2, dy: line / 2), xRadius: size * 0.07, yRadius: size * 0.07)
outline.lineWidth = line
outline.stroke()

// Left half: solid, as if just snapped in.
let r = size * 0.025
let leftPane = NSRect(x: inner.minX + gap, y: inner.minY + gap, width: midX - inner.minX - gap * 1.5, height: inner.height - 2 * gap)
NSColor.white.setFill()
NSBezierPath(roundedRect: leftPane, xRadius: r, yRadius: r).fill()

// Right quarters: the top one solid, the bottom one faded.
let paneW = inner.maxX - midX - gap * 1.5, paneH = (inner.height - 3 * gap) / 2
let topRight = NSRect(x: midX + gap * 0.5, y: midY + gap * 0.5, width: paneW, height: paneH)
let bottomRight = NSRect(x: midX + gap * 0.5, y: inner.minY + gap, width: paneW, height: paneH)
NSColor.white.withAlphaComponent(0.8).setFill()
NSBezierPath(roundedRect: topRight, xRadius: r, yRadius: r).fill()
NSColor.white.withAlphaComponent(0.4).setFill()
NSBezierPath(roundedRect: bottomRight, xRadius: r, yRadius: r).fill()

image.unlockFocus()
let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
