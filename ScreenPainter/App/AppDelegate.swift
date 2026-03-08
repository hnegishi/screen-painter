import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    let appSettings = AppSettings()
    let drawingEngine = DrawingEngine()
    var overlayController: OverlayWindowController?
    var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !Permissions.isAccessibilityGranted() {
            Permissions.requestAccessibility()
        }

        overlayController = OverlayWindowController(drawingEngine: drawingEngine, appSettings: appSettings)
        overlayController?.showOverlays()

        hotkeyManager = HotkeyManager(
            appSettings: appSettings,
            drawingEngine: drawingEngine,
            overlayController: overlayController!
        )
        hotkeyManager?.start()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screenParametersChanged() {
        overlayController?.rebuildOverlays()
    }
}
