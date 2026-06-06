import AppKit
import Combine
import SwiftUI

@MainActor
final class AgentWindowController {
    private let store: AgentStore
    private let panel: AgentPanel
    private var dragStartOrigin: NSPoint?

    init(store: AgentStore) {
        self.store = store
        panel = AgentPanel(
            contentRect: CGRect(origin: .zero, size: AgentLayout.panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.title = "Pixel Agent"
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false

        panel.contentView = NSHostingView(
            rootView: AgentPanelView(
                store: store,
                onDragChanged: { [weak self] translation in
                    self?.drag(by: translation)
                },
                onDragEnded: { [weak self] in
                    self?.endDrag()
                }
            )
        )
        restoreFrame()
    }

    func show() {
        if panel.frame.origin == .zero {
            restoreFrame()
        }
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func drag(by translation: CGSize) {
        if dragStartOrigin == nil {
            dragStartOrigin = panel.frame.origin
        }
        guard let start = dragStartOrigin else { return }
        panel.setFrameOrigin(NSPoint(
            x: start.x + translation.width,
            y: start.y - translation.height
        ))
    }

    private func endDrag() {
        dragStartOrigin = nil
        saveFrame()
    }

    private func restoreFrame() {
        let defaults = UserDefaults.standard
        let savedX = defaults.object(forKey: DefaultsKeys.panelX) as? Double
        let savedY = defaults.object(forKey: DefaultsKeys.panelY) as? Double
        let size = AgentLayout.panelSize

        if let savedX, let savedY {
            panel.setFrame(CGRect(x: savedX, y: savedY, width: size.width, height: size.height), display: false)
            return
        }

        let screen = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = NSPoint(
            x: screen.maxX - size.width - 32,
            y: screen.minY + 64
        )
        panel.setFrame(CGRect(origin: origin, size: size), display: false)
    }

    private func saveFrame() {
        UserDefaults.standard.set(panel.frame.origin.x, forKey: DefaultsKeys.panelX)
        UserDefaults.standard.set(panel.frame.origin.y, forKey: DefaultsKeys.panelY)
    }
}

private enum DefaultsKeys {
    static let panelX = "panel.origin.x"
    static let panelY = "panel.origin.y"
}
