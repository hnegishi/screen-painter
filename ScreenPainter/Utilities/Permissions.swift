import Cocoa

struct Permissions {
    static func isAccessibilityGranted() -> Bool {
        return AXIsProcessTrusted()
    }

    static func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
