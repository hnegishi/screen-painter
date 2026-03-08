import SwiftUI

@main
struct ScreenPainterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("ScreenPainter", systemImage: "paintbrush.fill") {
            MenuBarView()
                .environmentObject(appDelegate.appSettings)
                .environmentObject(appDelegate.drawingEngine)
        }

        Settings {
            SettingsView()
                .environmentObject(appDelegate.appSettings)
        }
    }
}
