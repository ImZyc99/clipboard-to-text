import AppKit

enum BrandIcon {
    /// A small-size vector companion to the brown application icon.
    /// Template rendering keeps the background clear and follows menu-bar contrast.
    static func menuBarImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 20, height: 20), flipped: true) { _ in
            NSColor.black.setStroke()
            let paper = NSBezierPath()
            paper.lineWidth = 1.5
            paper.lineCapStyle = .round
            paper.lineJoinStyle = .round
            paper.move(to: NSPoint(x: 6.5, y: 4.5))
            paper.line(to: NSPoint(x: 4.5, y: 4.5))
            paper.curve(to: NSPoint(x: 3, y: 6), controlPoint1: NSPoint(x: 3.5, y: 4.5), controlPoint2: NSPoint(x: 3, y: 5))
            paper.line(to: NSPoint(x: 3, y: 16.5))
            paper.curve(to: NSPoint(x: 4.5, y: 18), controlPoint1: NSPoint(x: 3, y: 17.5), controlPoint2: NSPoint(x: 3.5, y: 18))
            paper.line(to: NSPoint(x: 12, y: 18))
            paper.line(to: NSPoint(x: 17, y: 13))
            paper.line(to: NSPoint(x: 17, y: 6))
            paper.curve(to: NSPoint(x: 15.5, y: 4.5), controlPoint1: NSPoint(x: 17, y: 5), controlPoint2: NSPoint(x: 16.5, y: 4.5))
            paper.line(to: NSPoint(x: 13.5, y: 4.5))
            paper.move(to: NSPoint(x: 12, y: 18))
            paper.line(to: NSPoint(x: 12, y: 14.5))
            paper.curve(to: NSPoint(x: 13.5, y: 13), controlPoint1: NSPoint(x: 12, y: 13.5), controlPoint2: NSPoint(x: 12.5, y: 13))
            paper.line(to: NSPoint(x: 17, y: 13))
            paper.move(to: NSPoint(x: 6.5, y: 9))
            paper.line(to: NSPoint(x: 13, y: 9))
            paper.move(to: NSPoint(x: 6.5, y: 12))
            paper.line(to: NSPoint(x: 10.5, y: 12))
            paper.stroke()

            let clip = NSBezierPath()
            clip.lineWidth = 1.5
            clip.lineJoinStyle = .round
            clip.move(to: NSPoint(x: 7, y: 6))
            clip.line(to: NSPoint(x: 13, y: 6))
            clip.line(to: NSPoint(x: 13, y: 3.5))
            clip.line(to: NSPoint(x: 11.75, y: 3.5))
            clip.curve(to: NSPoint(x: 8.25, y: 3.5), controlPoint1: NSPoint(x: 11.75, y: 0.75), controlPoint2: NSPoint(x: 8.25, y: 0.75))
            clip.line(to: NSPoint(x: 7, y: 3.5))
            clip.close()
            clip.stroke()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "剪贴成文"
        return image
    }
}
