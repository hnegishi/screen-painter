import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings

    @State private var isRecordingHotkey = false
    @State private var isRecordingClearKey = false

    var body: some View {
        Form {
            Section("ホットキー") {
                HStack {
                    Text("描画キー:")
                    Spacer()
                    Button(isRecordingHotkey ? "キーを押してください..." : AppSettings.keyName(for: appSettings.hotkeyKeyCode)) {
                        isRecordingHotkey = true
                        isRecordingClearKey = false
                    }
                    .buttonStyle(.bordered)
                }

                HStack {
                    Text("クリアキー:")
                    Spacer()
                    Button(isRecordingClearKey ? "キーを押してください..." : AppSettings.keyName(for: appSettings.clearKeyCode)) {
                        isRecordingClearKey = true
                        isRecordingHotkey = false
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section("モード") {
                Picker("描画モード:", selection: Binding(
                    get: { appSettings.drawingMode },
                    set: { appSettings.drawingMode = $0 }
                )) {
                    ForEach(DrawingMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text(appSettings.drawingMode == .hold
                     ? "キーを押している間だけ描画できます"
                     : "キーを押すたびに描画モードのON/OFFが切り替わります")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("外観") {
                ColorPicker("ペイントの色:", selection: Binding(
                    get: { appSettings.swiftUIPaintColor },
                    set: { appSettings.swiftUIPaintColor = $0 }
                ))

                HStack {
                    Text("線の太さ:")
                    Slider(value: $appSettings.lineWidth, in: 1...20)
                    Text("\(appSettings.lineWidth, specifier: "%.1f")")
                        .frame(width: 40)
                }
            }

            Section("消去設定") {
                HStack {
                    Text("自動消去までの秒数:")
                    Slider(value: $appSettings.disappearDelay, in: 0...20)
                    Text(appSettings.disappearDelay == 0
                         ? "なし"
                         : "\(appSettings.disappearDelay, specifier: "%.1f")秒")
                        .frame(width: 60)
                }

                Text(appSettings.disappearDelay == 0
                     ? "描画はクリアキーで手動で消去します"
                     : "描画は\(appSettings.disappearDelay, specifier: "%.1f")秒後に自動的に消えます")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 400)
        .background(KeyCaptureView(
            isRecordingHotkey: $isRecordingHotkey,
            isRecordingClearKey: $isRecordingClearKey,
            appSettings: appSettings
        ))
    }
}

struct KeyCaptureView: NSViewRepresentable {
    @Binding var isRecordingHotkey: Bool
    @Binding var isRecordingClearKey: Bool
    let appSettings: AppSettings

    func makeNSView(context: Context) -> KeyCaptureNSView {
        let view = KeyCaptureNSView()
        view.onKeyPressed = { keyCode in
            if isRecordingHotkey {
                appSettings.hotkeyKeyCode = Int(keyCode)
                isRecordingHotkey = false
            } else if isRecordingClearKey {
                appSettings.clearKeyCode = Int(keyCode)
                isRecordingClearKey = false
            }
        }
        return view
    }

    func updateNSView(_ nsView: KeyCaptureNSView, context: Context) {
        nsView.isCapturing = isRecordingHotkey || isRecordingClearKey
        nsView.onKeyPressed = { keyCode in
            if isRecordingHotkey {
                appSettings.hotkeyKeyCode = Int(keyCode)
                isRecordingHotkey = false
            } else if isRecordingClearKey {
                appSettings.clearKeyCode = Int(keyCode)
                isRecordingClearKey = false
            }
        }
        if nsView.isCapturing {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }
}

class KeyCaptureNSView: NSView {
    var onKeyPressed: ((UInt16) -> Void)?
    var isCapturing: Bool = false

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if isCapturing {
            onKeyPressed?(event.keyCode)
        } else {
            super.keyDown(with: event)
        }
    }

    override func flagsChanged(with event: NSEvent) {
        if isCapturing {
            onKeyPressed?(event.keyCode)
        } else {
            super.flagsChanged(with: event)
        }
    }
}
