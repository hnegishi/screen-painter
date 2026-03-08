import Cocoa

class OverlayWindowController {
    private var overlayWindows: [(NSWindow, OverlayView)] = []
    private let drawingEngine: DrawingEngine

    init(drawingEngine: DrawingEngine) {
        self.drawingEngine = drawingEngine
    }

    func showOverlays() {
        for screen in NSScreen.screens {
            let window = createOverlayWindow(for: screen)
            let overlayView = OverlayView(drawingEngine: drawingEngine)
            overlayView.frame = window.contentView!.bounds
            overlayView.autoresizingMask = [.width, .height]
            window.contentView?.addSubview(overlayView)
            window.orderFrontRegardless()
            overlayWindows.append((window, overlayView))
        }
    }

    func rebuildOverlays() {
        for (window, _) in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
        showOverlays()
    }

    func setAcceptsMouseEvents(_ accepts: Bool) {
        for (window, _) in overlayWindows {
            window.ignoresMouseEvents = !accepts
        }
    }

    func setNeedsDisplay() {
        for (_, view) in overlayWindows {
            view.needsDisplay = true
        }
    }

    private func createOverlayWindow(for screen: NSScreen) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .statusBar + 1
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.hasShadow = false
        return window
    }
}
