#!/usr/bin/env swift
// Generates the Define app icon: Support/AppIcon.icns and docs/icon.png.
// Run from the repo root:  swift Scripts/generate-icon.swift
//
// The icon is drawn in code so it can be regenerated/tweaked without
// design tools: a macOS-style squircle with an indigo-to-sky gradient
// and the same SF Symbol glyph the menu bar item uses.

import AppKit

let canvas: CGFloat = 1024
// Apple's icon grid: the squircle fills ~824pt of a 1024pt canvas,
// leaving a transparent margin so the system drop shadow has room.
let plateRect = NSRect(x: 100, y: 100, width: 824, height: 824)
let cornerRadius: CGFloat = 186

func tintedSymbol(named name: String, pointSize: CGFloat) -> NSImage {
    let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
    guard let symbol = NSImage(
        systemSymbolName: name, accessibilityDescription: nil
    )?.withSymbolConfiguration(config) else {
        fatalError("missing SF Symbol \(name)")
    }
    let tinted = NSImage(size: symbol.size)
    tinted.lockFocus()
    let rect = NSRect(origin: .zero, size: symbol.size)
    symbol.draw(in: rect)
    NSColor.white.set()
    rect.fill(using: .sourceAtop)
    tinted.unlockFocus()
    return tinted
}

func drawIcon() -> NSImage {
    let image = NSImage(size: NSSize(width: canvas, height: canvas))
    image.lockFocus()

    let plate = NSBezierPath(roundedRect: plateRect, xRadius: cornerRadius, yRadius: cornerRadius)

    // Soft shadow under the plate.
    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.shadowBlurRadius = 28
    shadow.set()
    NSColor(calibratedRed: 0.16, green: 0.23, blue: 0.65, alpha: 1).setFill()
    plate.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    // Indigo → sky vertical gradient.
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.13, green: 0.17, blue: 0.55, alpha: 1),
        NSColor(calibratedRed: 0.20, green: 0.45, blue: 0.95, alpha: 1),
        NSColor(calibratedRed: 0.38, green: 0.68, blue: 1.00, alpha: 1),
    ])!
    gradient.draw(in: plate, angle: 90)

    // Faint top sheen for depth.
    let sheenRect = NSRect(
        x: plateRect.minX, y: plateRect.midY,
        width: plateRect.width, height: plateRect.height / 2
    )
    let sheen = NSBezierPath(roundedRect: sheenRect, xRadius: cornerRadius, yRadius: cornerRadius)
    NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.0),
        NSColor.white.withAlphaComponent(0.12),
    ])!.draw(in: sheen, angle: 90)

    // The glyph — same symbol as the menu bar item, with a soft shadow.
    NSGraphicsContext.current?.saveGraphicsState()
    let glyphShadow = NSShadow()
    glyphShadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
    glyphShadow.shadowOffset = NSSize(width: 0, height: -8)
    glyphShadow.shadowBlurRadius = 16
    glyphShadow.set()
    let glyph = tintedSymbol(named: "character.book.closed.fill", pointSize: 460)
    let glyphSize = glyph.size
    glyph.draw(in: NSRect(
        x: (canvas - glyphSize.width) / 2,
        y: (canvas - glyphSize.height) / 2,
        width: glyphSize.width,
        height: glyphSize.height
    ))
    NSGraphicsContext.current?.restoreGraphicsState()

    image.unlockFocus()
    return image
}

func pngData(of image: NSImage, pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(
        in: NSRect(x: 0, y: 0, width: pixels, height: pixels),
        from: NSRect(origin: .zero, size: image.size),
        operation: .copy, fraction: 1
    )
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let fm = FileManager.default
let iconset = "build/AppIcon.iconset"
try? fm.removeItem(atPath: iconset)
try fm.createDirectory(atPath: iconset, withIntermediateDirectories: true)
try fm.createDirectory(atPath: "Support", withIntermediateDirectories: true)
try fm.createDirectory(atPath: "docs", withIntermediateDirectories: true)

let icon = drawIcon()
let entries: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]
for (name, pixels) in entries {
    try pngData(of: icon, pixels: pixels).write(to: URL(fileURLWithPath: "\(iconset)/\(name)"))
}
try pngData(of: icon, pixels: 512).write(to: URL(fileURLWithPath: "docs/icon.png"))

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset, "-o", "Support/AppIcon.icns"]
try iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else { fatalError("iconutil failed") }

print("Wrote Support/AppIcon.icns and docs/icon.png")
