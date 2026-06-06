import AppKit
import SwiftUI

struct PixelSpriteFrameView: NSViewRepresentable {
    let image: NSImage
    let sourceRect: CGRect

    func makeNSView(context: Context) -> SpriteFrameNSView {
        let view = SpriteFrameNSView()
        view.image = image
        view.sourceRect = sourceRect
        return view
    }

    func updateNSView(_ nsView: SpriteFrameNSView, context: Context) {
        nsView.image = image
        nsView.sourceRect = sourceRect
        nsView.needsDisplay = true
    }
}

final class SpriteFrameNSView: NSView {
    var image: NSImage?
    var sourceRect: CGRect = .zero

    override var isFlipped: Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let image else { return }
        NSGraphicsContext.current?.imageInterpolation = .none
        image.draw(
            in: bounds,
            from: sourceRect,
            operation: .sourceOver,
            fraction: 1.0,
            respectFlipped: false,
            hints: [.interpolation: NSImageInterpolation.none]
        )
    }
}
