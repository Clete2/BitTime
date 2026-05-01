#!/usr/bin/env swift
//
// Generate the BitTime DMG background image.
//
// Usage:  swift scripts/make-dmg-background.swift <output.png>
//
// Produces a 600x400 dark-mode PNG with:
//   - a centered right-pointing arrow with a "Drag to install" caption
//   - translucent rounded "pill" backgrounds behind the icon labels so the
//     white label text stays readable against the dark background
//
// Layout (top-origin coords) must match the AppleScript icon positions in
// scripts/build-release.sh:
//
//     BitTime.app   center @ (150, 180)
//     Applications  center @ (450, 180)
//
// Uses only AppKit / CoreGraphics — no third-party dependencies.
//

import AppKit
import CoreGraphics
import Foundation

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: make-dmg-background.swift <output.png>\n".utf8))
    exit(2)
}
let outputPath = CommandLine.arguments[1]

let width = 600
let height = 400

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    FileHandle.standardError.write(Data("error: failed to create CGContext\n".utf8))
    exit(1)
}

let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: false)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = nsCtx

// CoreGraphics origin is bottom-left; convert top-origin Y to CG Y.
func cgY(_ topY: CGFloat) -> CGFloat { CGFloat(height) - topY }

// -- Background fill (dark) ----------------------------------------------------
let bg = NSColor(calibratedRed: 30.0/255.0, green: 30.0/255.0, blue: 30.0/255.0, alpha: 1.0)
bg.setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()

// -- Geometry ------------------------------------------------------------------
// Icon center positions (top-origin) — must match AppleScript positions.
// Finder draws the label below the icon, so the visual center of the
// icon+label block is below the icon center. Pulling the icon center up
// above the geometric middle of the window centers the visible block.
let iconY: CGFloat = 160
let leftIconX: CGFloat = 150
let rightIconX: CGFloat = 450
let iconHalf: CGFloat = 64 // 128px icon, half-extent

// Arrow lives between the inner edges of the two icons, centered vertically
// on the icon center.
let gapPadding: CGFloat = 18
let shaftLeft = leftIconX + iconHalf + gapPadding   // 232
let shaftRight = rightIconX - iconHalf - gapPadding // 368
let shaftThickness: CGFloat = 8
let headSize: CGFloat = 22

let cy = cgY(iconY)

// -- Arrow ---------------------------------------------------------------------
let arrowColor = NSColor(calibratedRed: 210.0/255.0, green: 210.0/255.0, blue: 215.0/255.0, alpha: 1.0)
arrowColor.setFill()

// Shaft: rounded-left, flat-right (the flat right end tucks behind the
// arrowhead so the two shapes merge into a single arrow).
let shaftEnd = shaftRight - headSize * 0.6
let shaftRect = NSRect(
    x: shaftLeft,
    y: cy - shaftThickness / 2,
    width: shaftEnd - shaftLeft,
    height: shaftThickness
)
let radius = shaftThickness / 2
let shaftPath = NSBezierPath()
shaftPath.move(to: NSPoint(x: shaftRect.maxX, y: shaftRect.maxY))
shaftPath.line(to: NSPoint(x: shaftRect.minX + radius, y: shaftRect.maxY))
shaftPath.appendArc(
    withCenter: NSPoint(x: shaftRect.minX + radius, y: shaftRect.midY),
    radius: radius,
    startAngle: 90,
    endAngle: 270
)
shaftPath.line(to: NSPoint(x: shaftRect.maxX, y: shaftRect.minY))
shaftPath.close()
shaftPath.fill()

// Arrowhead (filled triangle).
let head = NSBezierPath()
head.move(to: NSPoint(x: shaftEnd, y: cy + headSize))
head.line(to: NSPoint(x: shaftRight, y: cy))
head.line(to: NSPoint(x: shaftEnd, y: cy - headSize))
head.close()
head.fill()

// -- Caption -------------------------------------------------------------------
let captionColor = NSColor(calibratedRed: 225.0/255.0, green: 225.0/255.0, blue: 230.0/255.0, alpha: 1.0)
let captionFont = NSFont.systemFont(ofSize: 16, weight: .medium)
let captionAttrs: [NSAttributedString.Key: Any] = [
    .font: captionFont,
    .foregroundColor: captionColor,
]
let caption = "Drag to install" as NSString
let captionSize = caption.size(withAttributes: captionAttrs)
let arrowCenterX = (shaftLeft + shaftRight) / 2
let captionX = arrowCenterX - captionSize.width / 2
let captionY = (cy - headSize) - 16 - captionSize.height
caption.draw(at: NSPoint(x: captionX, y: captionY), withAttributes: captionAttrs)

// -- Label "pills" -------------------------------------------------------------
// Finder draws icon labels just below the icon. We bake a translucent rounded
// rectangle behind each label so the system-rendered text stays readable.
// Finder places the label baseline ~8pt below the icon's bottom edge with a
// label box height that scales with the icon's text size (13pt -> ~20pt).
let labelPillFill = NSColor(calibratedWhite: 1.0, alpha: 0.95)
let labelPillStroke = NSColor(calibratedWhite: 1.0, alpha: 1.0)

func drawLabelPill(centerX: CGFloat, iconCenterTopY: CGFloat, text: String) {
    // Estimate label width using the same font Finder uses (system 13pt).
    let probeFont = NSFont.systemFont(ofSize: 13)
    let probeWidth = (text as NSString).size(withAttributes: [.font: probeFont]).width
    let pillWidth = max(probeWidth + 24, 90)
    let pillHeight: CGFloat = 22

    // Top of label box ~ iconBottom + 6; iconBottom = iconCenter + iconHalf.
    let iconBottomTopY = iconCenterTopY + iconHalf
    let pillTopY = iconBottomTopY + 6
    let pillRect = NSRect(
        x: centerX - pillWidth / 2,
        y: cgY(pillTopY + pillHeight),
        width: pillWidth,
        height: pillHeight
    )
    let path = NSBezierPath(roundedRect: pillRect, xRadius: 6, yRadius: 6)
    labelPillFill.setFill()
    path.fill()
    labelPillStroke.setStroke()
    path.lineWidth = 1
    path.stroke()
}

drawLabelPill(centerX: leftIconX, iconCenterTopY: iconY, text: "BitTime.app")
drawLabelPill(centerX: rightIconX, iconCenterTopY: iconY, text: "Applications")

NSGraphicsContext.restoreGraphicsState()

// -- Write PNG -----------------------------------------------------------------
guard let cgImage = ctx.makeImage() else {
    FileHandle.standardError.write(Data("error: failed to snapshot image\n".utf8))
    exit(1)
}
let rep = NSBitmapImageRep(cgImage: cgImage)
guard let pngData = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("error: failed to encode PNG\n".utf8))
    exit(1)
}
let url = URL(fileURLWithPath: outputPath)
do {
    try pngData.write(to: url)
} catch {
    FileHandle.standardError.write(Data("error: failed to write \(outputPath): \(error)\n".utf8))
    exit(1)
}
