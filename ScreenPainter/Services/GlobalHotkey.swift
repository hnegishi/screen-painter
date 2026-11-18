import Carbon.HIToolbox
import Foundation

/// Carbon の `RegisterEventHotKey` によるグローバルホットキー。
///
/// `NSEvent` のグローバルモニタはキー入力を覗けるだけで止められないが、こちらは登録している間、
/// 該当のキー入力を最前面のアプリに渡さずに受け取る。インスタンスが生きている間だけ登録され、
/// 解放時に解除される。
final class GlobalHotkey {
    private static let signature: OSType = 0x5350_6E74 // "SPnt"

    private let hotKeyID: EventHotKeyID
    private let handler: () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    /// - Parameters:
    ///   - keyCode: 仮想キーコード（`kVK_ANSI_Z` など）
    ///   - modifiers: Carbon の修飾キーフラグ（`cmdKey | controlKey` など）
    ///   - handler: キーが押されたときにメインスレッドで呼ばれる
    init(keyCode: Int, modifiers: Int, handler: @escaping () -> Void) {
        // 同じ組み合わせは同時に1つしか登録できないので、組み合わせそのものを ID にする
        hotKeyID = EventHotKeyID(signature: GlobalHotkey.signature, id: UInt32((modifiers << 16) | keyCode))
        self.handler = handler

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, event, userData in
                guard let event = event, let userData = userData else { return OSStatus(eventNotHandledErr) }
                let hotkey = Unmanaged<GlobalHotkey>.fromOpaque(userData).takeUnretainedValue()
                return hotkey.handle(event)
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        let status = RegisterEventHotKey(
            UInt32(keyCode),
            UInt32(modifiers),
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        if status != noErr {
            NSLog("%@", "GlobalHotkey: 登録に失敗しました (keyCode: \(keyCode), modifiers: \(modifiers), status: \(status))")
        }
    }

    deinit {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandlerRef = eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    private func handle(_ event: EventRef) -> OSStatus {
        var pressedID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &pressedID
        )
        // 別のホットキーのイベントは、次のハンドラに任せる
        guard status == noErr, pressedID.signature == hotKeyID.signature, pressedID.id == hotKeyID.id else {
            return OSStatus(eventNotHandledErr)
        }
        handler()
        return noErr
    }
}
