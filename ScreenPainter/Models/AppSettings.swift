import SwiftUI
import Cocoa

class AppSettings: ObservableObject {
    // Hotkey: default is left Control key (keyCode 59)
    @AppStorage("hotkeyKeyCode") var hotkeyKeyCode: Int = 59
    @AppStorage("hotkeyModifiers") var hotkeyModifiers: Int = 0

    // Drawing mode: "hold" or "toggle"
    @AppStorage("drawingMode") var drawingModeRaw: String = DrawingMode.hold.rawValue

    // Disappear delay in seconds (0 = never auto-disappear)
    @AppStorage("disappearDelay") var disappearDelay: Double = 3.0

    // Paint color as hex string
    @AppStorage("paintColorHex") var paintColorHex: String = "#00FF00"

    // Clear key: default is Escape (keyCode 53)
    @AppStorage("clearKeyCode") var clearKeyCode: Int = 53

    // Line width
    @AppStorage("lineWidth") var lineWidth: Double = 3.0

    var drawingMode: DrawingMode {
        get { DrawingMode(rawValue: drawingModeRaw) ?? .hold }
        set { drawingModeRaw = newValue.rawValue }
    }

    var paintColor: NSColor {
        get { NSColor.fromHex(paintColorHex) ?? .red }
        set { paintColorHex = newValue.toHex() }
    }

    var swiftUIPaintColor: Color {
        get { Color(paintColor) }
        set {
            if let cgColor = NSColor(newValue).usingColorSpace(.sRGB) {
                paintColor = cgColor
            }
        }
    }

    static func keyName(for keyCode: Int) -> String {
        let keyNames: [Int: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P",
            36: "Return", 37: "L", 38: "J", 39: "'", 40: "K", 41: ";",
            42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
            48: "Tab", 49: "Space", 50: "`", 51: "Delete", 53: "Escape",
            54: "Right Command", 55: "Left Command", 56: "Left Shift",
            57: "Caps Lock", 58: "Left Option", 59: "Left Control",
            60: "Right Shift", 61: "Right Option", 62: "Right Control",
            63: "Function",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5",
            97: "F6", 98: "F7", 100: "F8", 101: "F9", 109: "F10",
            103: "F11", 111: "F12",
            123: "Left Arrow", 124: "Right Arrow", 125: "Down Arrow", 126: "Up Arrow"
        ]
        return keyNames[keyCode] ?? "Key \(keyCode)"
    }
}

extension NSColor {
    static func fromHex(_ hex: String) -> NSColor? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6 else { return nil }

        var rgbValue: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgbValue)

        return NSColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }

    func toHex() -> String {
        guard let color = self.usingColorSpace(.sRGB) else { return "#FF0000" }
        let r = Int(color.redComponent * 255)
        let g = Int(color.greenComponent * 255)
        let b = Int(color.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
