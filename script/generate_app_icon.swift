#!/usr/bin/env swift

import AppKit

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: generate_app_icon.swift <output.iconset>\n".utf8))
    exit(2)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

let iconEntries: [(name: String, pixels: CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for entry in iconEntries {
    let image = makeIcon(size: entry.pixels)
    let destination = outputURL.appendingPathComponent(entry.name)
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let data = bitmap.representation(using: .png, properties: [:])
    else {
        FileHandle.standardError.write(Data("failed to render \(entry.name)\n".utf8))
        exit(1)
    }
    try data.write(to: destination, options: .atomic)
}

func makeIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let scale = size / 1024
    let cornerRadius = 220 * scale

    NSGraphicsContext.current?.imageInterpolation = .high

    let basePath = NSBezierPath(roundedRect: rect.insetBy(dx: 26 * scale, dy: 26 * scale), xRadius: cornerRadius, yRadius: cornerRadius)
    NSColor.clear.setFill()
    rect.fill()
    basePath.addClip()

    drawGradient(
        in: rect,
        colors: [
            NSColor(calibratedRed: 0.10, green: 0.60, blue: 1.00, alpha: 1.0),
            NSColor(calibratedRed: 0.37, green: 0.34, blue: 0.98, alpha: 1.0),
            NSColor(calibratedRed: 0.70, green: 0.37, blue: 1.00, alpha: 1.0)
        ],
        angle: 45
    )

    let upperGlow = NSBezierPath(ovalIn: NSRect(x: 88 * scale, y: 608 * scale, width: 860 * scale, height: 380 * scale))
    NSColor.white.withAlphaComponent(0.32).setFill()
    upperGlow.fill()

    let lowerGlow = NSBezierPath(ovalIn: NSRect(x: 120 * scale, y: 46 * scale, width: 790 * scale, height: 420 * scale))
    NSColor(calibratedRed: 0.00, green: 0.90, blue: 0.86, alpha: 0.22).setFill()
    lowerGlow.fill()

    let glassInset = 124 * scale
    let glassRect = rect.insetBy(dx: glassInset, dy: glassInset)
    let glassPath = NSBezierPath(roundedRect: glassRect, xRadius: 150 * scale, yRadius: 150 * scale)
    NSColor.white.withAlphaComponent(0.28).setFill()
    glassPath.fill()
    NSColor.white.withAlphaComponent(0.38).setStroke()
    glassPath.lineWidth = 7 * scale
    glassPath.stroke()

    let cardRect = NSRect(x: 304 * scale, y: 248 * scale, width: 416 * scale, height: 508 * scale)
    let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 72 * scale, yRadius: 72 * scale)
    shadow(color: NSColor.black.withAlphaComponent(0.20), blur: 38 * scale, y: -16 * scale) {
        NSColor.white.withAlphaComponent(0.88).setFill()
        cardPath.fill()
    }

    let headerRect = NSRect(x: cardRect.minX, y: cardRect.maxY - 126 * scale, width: cardRect.width, height: 126 * scale)
    let headerPath = NSBezierPath(roundedRect: headerRect, xRadius: 72 * scale, yRadius: 72 * scale)
    NSColor(calibratedRed: 0.10, green: 0.55, blue: 1.00, alpha: 0.70).setFill()
    headerPath.fill()

    let maskRect = NSRect(x: cardRect.minX, y: cardRect.minY, width: cardRect.width, height: cardRect.height - 80 * scale)
    NSColor.white.withAlphaComponent(0.88).setFill()
    maskRect.fill()

    drawLine(x: 376, y: 536, width: 272, scale: scale)
    drawLine(x: 376, y: 458, width: 220, scale: scale)
    drawLine(x: 376, y: 380, width: 272, scale: scale)

    let clipCenter = NSPoint(x: 512 * scale, y: 748 * scale)
    let clipPath = NSBezierPath(roundedRect: NSRect(x: clipCenter.x - 98 * scale, y: clipCenter.y - 52 * scale, width: 196 * scale, height: 104 * scale), xRadius: 52 * scale, yRadius: 52 * scale)
    NSColor.white.withAlphaComponent(0.90).setFill()
    clipPath.fill()
    NSColor.white.withAlphaComponent(0.34).setStroke()
    clipPath.lineWidth = 8 * scale
    clipPath.stroke()

    NSColor.white.withAlphaComponent(0.55).setStroke()
    basePath.lineWidth = 10 * scale
    basePath.stroke()

    image.unlockFocus()
    return image
}

func drawLine(x: CGFloat, y: CGFloat, width: CGFloat, scale: CGFloat) {
    let path = NSBezierPath(roundedRect: NSRect(x: x * scale, y: y * scale, width: width * scale, height: 30 * scale), xRadius: 15 * scale, yRadius: 15 * scale)
    NSColor(calibratedWhite: 0.10, alpha: 0.32).setFill()
    path.fill()
}

func drawGradient(in rect: NSRect, colors: [NSColor], angle: CGFloat) {
    let gradient = NSGradient(colors: colors)
    gradient?.draw(in: rect, angle: angle)
}

func shadow(color: NSColor, blur: CGFloat, y: CGFloat, drawing: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color
    shadow.shadowBlurRadius = blur
    shadow.shadowOffset = NSSize(width: 0, height: y)
    shadow.set()
    drawing()
    NSGraphicsContext.restoreGraphicsState()
}
