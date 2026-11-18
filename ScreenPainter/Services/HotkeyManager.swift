import Carbon.HIToolbox
import Cocoa

class HotkeyManager {
    /// 取り消しは Cmd+Z 固定
    private static let undoKeyCode = kVK_ANSI_Z
    /// 取り消した直後も Cmd+Z を受け取り続ける秒数。連打で1回多く押した分が最前面のアプリに届き、
    /// そちらの「取り消す」が実行されるのを防ぐ。
    private static let undoGraceInterval: TimeInterval = 1.0

    private let appSettings: AppSettings
    private let drawingEngine: DrawingEngine
    private let overlayController: OverlayWindowController
    private var globalMouseMonitor: Any?
    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?
    private var localMouseMonitor: Any?
    private var displayTimer: Timer?
    private var toggleKeyWasPressed: Bool = false
    private var undoHotkeys: [GlobalHotkey] = []
    private var undoHotkeyModifiers: Set<Int> = []
    private var undoGraceDeadline: TimeInterval = 0

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
        undoHotkeys.removeAll()
        undoHotkeyModifiers.removeAll()
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
        guard isHotkeyMatch else { return }

        let isPressed: Bool
        if event.type == .keyDown {
            isPressed = true
        } else if event.type == .flagsChanged {
            isPressed = isModifierPressed(event)
        } else {
            return
        }

        // キーが押された瞬間のみトグル（リピート防止）
        if isPressed && !toggleKeyWasPressed {
            toggleKeyWasPressed = true
            if drawingEngine.isDrawingActive {
                drawingEngine.isDrawingActive = false
                drawingEngine.finalizeStroke(disappearDelay: appSettings.disappearDelay)
                overlayController.setAcceptsMouseEvents(false)
                overlayController.setNeedsDisplay()
            } else {
                drawingEngine.isDrawingActive = true
                overlayController.setAcceptsMouseEvents(true)
            }
        } else if !isPressed {
            toggleKeyWasPressed = false
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

        // カーソルを描画中も維持
        NSCursor.crosshair.set()

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

            // holdモード時、モディファイアキーのリリースイベントを取りこぼした場合の安全弁
            if self.drawingEngine.isDrawingActive && self.appSettings.drawingMode == .hold {
                if !self.isHotkeyCurrentlyPressed() {
                    self.deactivateDrawing()
                }
            }

            self.syncUndoHotkeys()

            if !self.drawingEngine.activeStrokes.isEmpty || self.drawingEngine.isDrawingActive {
                self.overlayController.setNeedsDisplay()
            }
        }
    }

    private func isHotkeyCurrentlyPressed() -> Bool {
        let flags = NSEvent.modifierFlags
        let keyCode = appSettings.hotkeyKeyCode
        switch keyCode {
        case 59, 62: return flags.contains(.control)
        case 55, 54: return flags.contains(.command)
        case 56, 60: return flags.contains(.shift)
        case 58, 61: return flags.contains(.option)
        default: return false
        }
    }

    private func deactivateDrawing() {
        drawingEngine.isDrawingActive = false
        drawingEngine.finalizeStroke(disappearDelay: appSettings.disappearDelay)
        overlayController.setAcceptsMouseEvents(false)
        overlayController.setNeedsDisplay()
    }

    // MARK: - 取り消し（Cmd+Z）

    /// 取り消せる描画がある間だけ Cmd+Z を登録する。登録中の Cmd+Z は最前面のアプリに届かないので、
    /// それ以外のときは登録を外し、通常の Cmd+Z を邪魔しない。
    private func syncUndoHotkeys() {
        let shouldCapture = drawingEngine.canUndo
            || ProcessInfo.processInfo.systemUptime < undoGraceDeadline
            // 押しっぱなしの途中で登録を外すと、続くキーリピートが最前面のアプリに届いてしまう
            || (!undoHotkeys.isEmpty && isUndoKeyDown)

        let modifiers = shouldCapture ? undoModifierCombinations : []
        guard modifiers != undoHotkeyModifiers else { return }

        // 同じ組み合わせは二重に登録できないので、先に解除してから登録する
        undoHotkeys.removeAll()
        undoHotkeys = modifiers.map { modifiers in
            GlobalHotkey(keyCode: HotkeyManager.undoKeyCode, modifiers: modifiers) { [weak self] in
                self?.undoLastStroke()
            }
        }
        undoHotkeyModifiers = modifiers
    }

    /// Cmd+Z に加えて、描画キー（モディファイア）を押したままの Cmd+Z も受け取る
    private var undoModifierCombinations: Set<Int> {
        var combinations: Set<Int> = [cmdKey]
        switch appSettings.hotkeyKeyCode {
        case 59, 62: combinations.insert(cmdKey | controlKey)
        case 56, 60: combinations.insert(cmdKey | shiftKey)
        case 58, 61: combinations.insert(cmdKey | optionKey)
        default: break
        }
        return combinations
    }

    private var isUndoKeyDown: Bool {
        CGEventSource.keyState(.combinedSessionState, key: CGKeyCode(HotkeyManager.undoKeyCode))
    }

    private func undoLastStroke() {
        if drawingEngine.undoLastStroke() {
            undoGraceDeadline = ProcessInfo.processInfo.systemUptime + HotkeyManager.undoGraceInterval
        }
        overlayController.setNeedsDisplay()
    }
}
