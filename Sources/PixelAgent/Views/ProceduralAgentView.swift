import PixelAgentCore
import SwiftUI

struct ProceduralAgentView: View {
    let state: AgentState
    let frame: Int

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 128.0
            context.scaleBy(x: scale, y: scale)
            drawScene(context: context)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func drawScene(context: GraphicsContext) {
        pixel(context, x: 18, y: 48, w: 92, h: 10, color: Color(red: 0.36, green: 0.18, blue: 0.15))
        pixel(context, x: 20, y: 30, w: 88, h: 20, color: Color(red: 0.68, green: 0.50, blue: 0.31))
        pixel(context, x: 24, y: 33, w: 5, h: 5, color: Color(red: 0.88, green: 0.72, blue: 0.48))
        pixel(context, x: 92, y: 33, w: 5, h: 5, color: Color(red: 0.88, green: 0.72, blue: 0.48))
        pixel(context, x: 25, y: 58, w: 7, h: 32, color: Color(red: 0.42, green: 0.49, blue: 0.51))
        pixel(context, x: 96, y: 58, w: 7, h: 32, color: Color(red: 0.42, green: 0.49, blue: 0.51))

        let bob = CGFloat(state == .working ? frame % 2 : (frame / 3) % 2)
        let glow = state == .toolActive ? 0.95 : 0.55
        pixel(context, x: 44, y: 8 + bob, w: 40, h: 32, color: Color(red: 0.86, green: 0.88, blue: 0.89))
        pixel(context, x: 48, y: 12 + bob, w: 32, h: 20, color: Color(red: 0.13, green: 0.20, blue: 0.18))
        pixel(context, x: 52, y: 16 + bob, w: 5, h: 5, color: Color(red: 0.39, green: glow, blue: 0.49))
        pixel(context, x: 60, y: 16 + bob, w: 5, h: 5, color: Color(red: 0.39, green: glow, blue: 0.49))
        pixel(context, x: 68, y: 16 + bob, w: 5, h: 5, color: Color(red: 0.39, green: glow, blue: 0.49))
        pixel(context, x: 53, y: 35 + bob, w: 22, h: 6, color: Color(red: 0.76, green: 0.78, blue: 0.78))

        pixel(context, x: 48, y: 48, w: 32, h: 38, color: Color(red: 0.08, green: 0.08, blue: 0.09))
        pixel(context, x: 42, y: 52, w: 8, h: 26, color: Color(red: 0.09, green: 0.09, blue: 0.11))
        pixel(context, x: 78, y: 52, w: 8, h: 26, color: Color(red: 0.09, green: 0.09, blue: 0.11))

        let handOffset = CGFloat(state == .completed ? (frame % 4 < 2 ? -7 : -2) : 0)
        let typingOffset = CGFloat(state == .working ? (frame % 2 == 0 ? -2 : 2) : 0)
        pixel(context, x: 38 + typingOffset, y: 76 + handOffset, w: 12, h: 9, color: Color(red: 0.70, green: 0.18, blue: 0.12))
        pixel(context, x: 78 - typingOffset, y: 76 + (state == .completed ? -2 : 0), w: 12, h: 9, color: Color(red: 0.70, green: 0.18, blue: 0.12))
        pixel(context, x: 50, y: 76, w: 28, h: 28, color: Color(red: 0.93, green: 0.43, blue: 0.14))
        pixel(context, x: 48, y: 102, w: 32, h: 8, color: Color(red: 0.18, green: 0.24, blue: 0.40))
        pixel(context, x: 40, y: 106, w: 48, h: 14, color: Color(red: 0.50, green: 0.75, blue: 0.55))

        if state == .idleVariant {
            let sleepy = frame % 8 < 4
            if sleepy {
                pixel(context, x: 85, y: 67, w: 4, h: 2, color: .white.opacity(0.85))
                pixel(context, x: 91, y: 63, w: 5, h: 2, color: .white.opacity(0.7))
                pixel(context, x: 98, y: 59, w: 6, h: 2, color: .white.opacity(0.55))
            } else {
                pixel(context, x: 52, y: 18, w: 4, h: 4, color: Color(red: 0.91, green: 0.94, blue: 0.50))
                pixel(context, x: 72, y: 22, w: 4, h: 4, color: Color(red: 0.50, green: 0.82, blue: 0.96))
            }
        }
    }

    private func pixel(
        _ context: GraphicsContext,
        x: CGFloat,
        y: CGFloat,
        w: CGFloat,
        h: CGFloat,
        color: Color
    ) {
        context.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(color))
    }
}
