import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var drawingEngine: DrawingEngine

    var body: some View {
        VStack {
            Text("Screen Painter")
                .font(.headline)

            Divider()

            HStack {
                Text("モード:")
                Text(appSettings.drawingMode.displayName)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("描画キー:")
                Text(AppSettings.keyName(for: appSettings.hotkeyKeyCode))
                    .foregroundColor(.secondary)
            }

            if drawingEngine.isDrawingActive {
                Text("描画中...")
                    .foregroundColor(.green)
            }

            Divider()

            Button("描画をクリア") {
                drawingEngine.clearAll()
            }
            .keyboardShortcut("k", modifiers: .command)

            Divider()

            if #available(macOS 14.0, *) {
                SettingsLink {
                    Text("設定...")
                }
            } else {
                Button("設定...") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
            }

            Divider()

            Button("終了") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(4)
    }
}
