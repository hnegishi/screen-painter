import Foundation

enum DrawingMode: String, CaseIterable, Identifiable {
    case hold = "hold"
    case toggle = "toggle"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hold: return "長押し"
        case .toggle: return "切り替え"
        }
    }
}
