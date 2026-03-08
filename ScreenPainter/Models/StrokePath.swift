import Cocoa
import Foundation

struct StrokePath: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    let color: NSColor
    let lineWidth: CGFloat
    var finalizedAt: Date?
}
