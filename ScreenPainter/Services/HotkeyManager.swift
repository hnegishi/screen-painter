import Cocoa

class HotkeyManager {
    private let appSettings: AppSettings
    private let drawingEngine: DrawingEngine
    private let overlayController: OverlayWindowController
    private var globalMouseMonitor: Any?
    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?
    private var localMouseMonitor: Any?
    private var displayTimer: Timer?

    init(appSettings: AppSettings, drawingEngine: DrawingEngine, overlayController: OverlayWindowController) {
        self.appSettings = appSettings
        self.drawingEngine = drawingEngine
        self.overlayController = overlayController
    }

    func start() {
        startGlobalMonitors()
        startDisplayTimer()
    }

    func stop() {
        stopGlobalMonitors()
        displayTimer?.invalidate()
        displayTimer = nil
    }

    private func startGlobalMonitors() {
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.keyDown, .keyUp, .flagsChanged]
        ) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]
        ) { [weak self] event in
            self?.handleMouseEvent(event)
        }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
            self?.handleKeyEvent(event)
            return event
        }

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]) { [weak self] event in
            self?.handleMouseEvent(event)
            return event
        }
    }

    private func stopGlobalMonitors() {
        if let monitor = globalKeyMonitor {
            NSEvent.removeMonitor(monitor)
            globalKeyMonitor = nil
        }
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMonitor = nil
        }
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyMonitor = nil
        }
        if let monitor = localMouseMonitor {
            NSEvent.removeMonitor(monitor)
            localMouseMonitor = nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        let keyCode = Int(event.keyCode)

        // Check for clear key
        if event.type == .keyDown && keyCode == appSettings.clearKeyCode {
            drawingEngine.clearAll()
            overlayController.setNeedsDisplay()
            return
        }

        // Check for hotkey
        let isHotkeyMatch = keyCode == appSettings.hotkeyKeyCode

        switch appSettings.drawingMode {
        case .hold:
            handleHoldMode(event: event, isHotkeyMatch: isHotkeyMatch)
        case .toggle:
            handleToggleMode(event: event, isHotkeyMatch: isHotkeyMatch)
        }
    }

    private func handleHoldMode(event: NSEvent, isHotkeyMatch: Bool) {
        guard isHotkeyMatch else { return }

        if event.type == .keyDown || (event.type == .flagsChanged && isModifierPressed(event)) {
            if !drawingEngine.isDrawingActive {
                drawingEngine.isDrawingActive = true
                overlayController.setAcceptsMouseEvents(true)
            }
        } else if event.type == .keyUp || (event.type == .flagsChanged && !isModifierPressed(event)) {
            if drawingEngine.isDrawingActive {
                drawingEngine.isDrawingActive = false
                drawingEngine.finalizeStroke(disappearDelay: appSettings.disappearDelay)
                overlayController.setAcceptsMouseEvents(false)
                overlayController.setNeedsDisplay()
            }
        }
    }

    private func handleToggleMode(event: NSEvent, isHotkeyMatch: Bool) {
        guard isHotkeyMatch && event.type == .keyDown else { return }

        if drawingEngine.isDrawingActive {
            drawingEngine.isDrawingActive = false
            drawingEngine.finalizeStroke(disappearDelay: appSettings.disappearDelay)
            overlayController.setAcceptsMouseEvents(false)
            overlayController.setNeedsDisplay()
        } else {
            drawingEngine.isDrawingActive = true
            overlayController.setAcceptsMouseEvents(true)
        }
    }

    private func isModifierPressed(_ event: NSEvent) -> Bool {
        let keyCode = Int(event.keyCode)
        switch keyCode {
        case 59, 62: return event.modifierFlags.contains(.control)
        case 55, 54: return event.modifierFlags.contains(.command)
        case 56, 60: return event.modifierFlags.contains(.shift)
        case 58, 61: return event.modifierFlags.contains(.option)
        default: return false
        }
    }

    private func handleMouseEvent(_ event: NSEvent) {
        guard drawingEngine.isDrawingActive else { return }

        let screenPoint = NSEvent.mouseLocation

        switch event.type {
        case .leftMouseDown:
            drawingEngine.beginStroke(
                at: screenPoint,
                color: appSettings.paintColor,
                lineWidth: CGFloat(appSettings.lineWidth)
            )
            overlayController.setNeedsDisplay()

        case .leftMouseDragged:
            drawingEngine.addPoint(screenPoint)
            overlayController.setNeedsDisplay()

        case .leftMouseUp:
            drawingEngine.addPoint(screenPoint)
            drawingEngine.finalizeStroke(disappearDelay: appSettings.disappearDelay)
            overlayController.setNeedsDisplay()

        default:
            break
        }
    }

    private func startDisplayTimer() {
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if !self.drawingEngine.activeStrokes.isEmpty || self.drawingEngine.isDrawingActive {
                self.overlayController.setNeedsDisplay()
            }
        }
    }
}
