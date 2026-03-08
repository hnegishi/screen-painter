import Cocoa

class OverlayView: NSView {
    private let drawingEngine: DrawingEngine

    init(drawingEngine: DrawingEngine) {
        self.drawingEngine = drawingEngine
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.clear(dirtyRect)

        let disappearDelay = UserDefaults.standard.double(forKey: "disappearDelay")

        // Draw finalized strokes
        for stroke in drawingEngine.activeStrokes {
            let alpha = drawingEngine.alphaForStroke(stroke, disappearDelay: disappearDelay)
            guard alpha > 0 else { continue }

            let screenPoints = convertScreenPoints(stroke.points)
            drawStroke(points: screenPoints, color: stroke.color.withAlphaComponent(alpha),
                      lineWidth: stroke.lineWidth)
        }

        // Draw current stroke
        if let current = drawingEngine.getCurrentStroke() {
            let screenPoints = convertScreenPoints(current.points)
            drawStroke(points: screenPoints, color: current.color, lineWidth: current.lineWidth)
        }
    }

    private func drawStroke(points: [CGPoint], color: NSColor, lineWidth: CGFloat) {
        guard !points.isEmpty else { return }

        let path = NSBezierPath()
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        path.move(to: points[0])
        for i in 1..<points.count {
            path.line(to: points[i])
        }

        if points.count == 1 {
            let dotRect = NSRect(
                x: points[0].x - lineWidth / 2,
                y: points[0].y - lineWidth / 2,
                width: lineWidth,
                height: lineWidth
            )
            color.setFill()
            NSBezierPath(ovalIn: dotRect).fill()
        } else {
            color.setStroke()
            path.stroke()
        }
    }

    private func convertScreenPoints(_ points: [CGPoint]) -> [CGPoint] {
        guard let window = self.window else { return points }
        return points.map { screenPoint in
            let windowPoint = window.convertPoint(fromScreen: screenPoint)
            return self.convert(windowPoint, from: nil)
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
}
