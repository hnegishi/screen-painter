import Cocoa
import Foundation

class DrawingEngine: ObservableObject {
    @Published var activeStrokes: [StrokePath] = []
    @Published var isDrawingActive: Bool = false

    private var currentStroke: StrokePath?
    private var fadeTimers: [UUID: Timer] = [:]

    func beginStroke(at point: CGPoint, color: NSColor, lineWidth: CGFloat) {
        currentStroke = StrokePath(
            points: [point],
            color: color,
            lineWidth: lineWidth
        )
    }

    func addPoint(_ point: CGPoint) {
        currentStroke?.points.append(point)
    }

    func getCurrentStroke() -> StrokePath? {
        return currentStroke
    }

    func finalizeStroke(disappearDelay: Double) {
        guard var stroke = currentStroke else { return }
        currentStroke = nil

        guard !stroke.points.isEmpty else { return }

        stroke.finalizedAt = Date()
        activeStrokes.append(stroke)

        if disappearDelay > 0 {
            let strokeId = stroke.id
            // フェードアウト完了後に削除（+0.1秒のマージン）
            let timer = Timer.scheduledTimer(withTimeInterval: disappearDelay + 0.6, repeats: false) { [weak self] _ in
                self?.removeStroke(id: strokeId)
            }
            fadeTimers[strokeId] = timer
        }
    }

    func clearAll() {
        activeStrokes.removeAll()
        currentStroke = nil
        for (_, timer) in fadeTimers {
            timer.invalidate()
        }
        fadeTimers.removeAll()
    }

    private func removeStroke(id: UUID) {
        activeStrokes.removeAll { $0.id == id }
        fadeTimers[id]?.invalidate()
        fadeTimers.removeValue(forKey: id)
    }

    func alphaForStroke(_ stroke: StrokePath, disappearDelay: Double) -> CGFloat {
        guard disappearDelay > 0, let finalizedAt = stroke.finalizedAt else { return 1.0 }

        let elapsed = Date().timeIntervalSince(finalizedAt)
        let fadeStart = disappearDelay - 0.5

        if elapsed < fadeStart {
            return 1.0
        } else if elapsed < disappearDelay {
            return CGFloat(1.0 - (elapsed - fadeStart) / 0.5)
        } else {
            return 0.0
        }
    }
}
