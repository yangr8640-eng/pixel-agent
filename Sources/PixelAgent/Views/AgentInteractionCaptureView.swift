import AppKit
import SwiftUI

struct AgentInteractionCaptureView: NSViewRepresentable {
    let onClick: () -> Void
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: () -> Void
    let onThreeFingerDragChanged: (CGSize) -> Void
    let onThreeFingerDragEnded: () -> Void

    func makeNSView(context: Context) -> InteractionCaptureNSView {
        let view = InteractionCaptureNSView()
        view.onClick = onClick
        view.onDragChanged = onDragChanged
        view.onDragEnded = onDragEnded
        view.onThreeFingerDragChanged = onThreeFingerDragChanged
        view.onThreeFingerDragEnded = onThreeFingerDragEnded
        return view
    }

    func updateNSView(_ nsView: InteractionCaptureNSView, context: Context) {
        nsView.onClick = onClick
        nsView.onDragChanged = onDragChanged
        nsView.onDragEnded = onDragEnded
        nsView.onThreeFingerDragChanged = onThreeFingerDragChanged
        nsView.onThreeFingerDragEnded = onThreeFingerDragEnded
    }
}

final class InteractionCaptureNSView: NSView {
    var onClick: (() -> Void)?
    var onDragChanged: ((CGSize) -> Void)?
    var onDragEnded: (() -> Void)?
    var onThreeFingerDragChanged: ((CGSize) -> Void)?
    var onThreeFingerDragEnded: (() -> Void)?

    private var mouseStart: CGPoint?
    private var mouseHasDragged = false
    private var threeFingerStart: CGPoint?
    private let clickMovementThreshold: CGFloat = 4
    private let touchSensitivity: CGFloat = 1.25

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsRestingTouches = true
        allowedTouchTypes = [.indirect]
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsRestingTouches = true
        allowedTouchTypes = [.indirect]
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        mouseStart = NSEvent.mouseLocation
        mouseHasDragged = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = mouseStart else { return }
        let current = NSEvent.mouseLocation
        let translation = CGSize(
            width: current.x - start.x,
            height: start.y - current.y
        )
        if abs(translation.width) > clickMovementThreshold || abs(translation.height) > clickMovementThreshold {
            mouseHasDragged = true
        }
        onDragChanged?(translation)
    }

    override func mouseUp(with event: NSEvent) {
        defer {
            mouseStart = nil
            mouseHasDragged = false
        }

        if mouseHasDragged {
            onDragEnded?()
        } else {
            onClick?()
        }
    }

    override func touchesBegan(with event: NSEvent) {
        updateThreeFingerDrag(with: event)
    }

    override func touchesMoved(with event: NSEvent) {
        updateThreeFingerDrag(with: event)
    }

    override func touchesEnded(with event: NSEvent) {
        finishThreeFingerDragIfNeeded(with: event)
    }

    override func touchesCancelled(with event: NSEvent) {
        finishThreeFingerDrag()
    }

    private func updateThreeFingerDrag(with event: NSEvent) {
        let touches = Array(event.touches(matching: .touching, in: self))
        guard touches.count >= 3 else { return }
        let centroid = centroid(of: touches)

        if threeFingerStart == nil {
            threeFingerStart = centroid
        }

        guard let start = threeFingerStart else { return }
        let translation = CGSize(
            width: (centroid.x - start.x) * touchSensitivity,
            height: (start.y - centroid.y) * touchSensitivity
        )
        onThreeFingerDragChanged?(translation)
    }

    private func finishThreeFingerDragIfNeeded(with event: NSEvent) {
        let touches = event.touches(matching: .touching, in: self)
        if touches.count < 3 {
            finishThreeFingerDrag()
        }
    }

    private func finishThreeFingerDrag() {
        guard threeFingerStart != nil else { return }
        threeFingerStart = nil
        onThreeFingerDragEnded?()
    }

    private func centroid(of touches: [NSTouch]) -> CGPoint {
        let points = touches.map { touch -> CGPoint in
            CGPoint(
                x: touch.normalizedPosition.x * touch.deviceSize.width,
                y: touch.normalizedPosition.y * touch.deviceSize.height
            )
        }
        let sum = points.reduce(CGPoint.zero) { partial, point in
            CGPoint(x: partial.x + point.x, y: partial.y + point.y)
        }
        let count = CGFloat(points.count)
        return CGPoint(x: sum.x / count, y: sum.y / count)
    }
}
