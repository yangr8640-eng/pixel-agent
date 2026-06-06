import SwiftUI

struct AgentPanelView: View {
    @ObservedObject var store: AgentStore
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: () -> Void

    @State private var reactionOffset: CGSize = .zero
    @State private var reactionRotation = 0.0

    var body: some View {
        ZStack(alignment: .top) {
            SpriteAnimatorView(store: store)
                .offset(reactionOffset)
                .rotationEffect(.degrees(reactionRotation), anchor: .bottom)
                .shadow(color: .black.opacity(0.22), radius: 4, x: 0, y: 2)
                .frame(width: AgentLayout.spriteSize.width, height: AgentLayout.spriteSize.height)
                .position(x: AgentLayout.panelSize.width / 2, y: AgentLayout.panelSize.height - AgentLayout.spriteSize.height / 2)

            if let bubble = currentBubble {
                Text(bubble.text)
                    .font(.system(size: bubble.fontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(bubble.foreground)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, bubble.horizontalPadding)
                    .padding(.vertical, bubble.verticalPadding)
                    .background(
                        SpeechBubbleShape()
                            .fill(bubble.background)
                            .shadow(color: bubble.shadow, radius: bubble.shadowRadius, x: 0, y: 1)
                    )
                    .overlay(
                        SpeechBubbleShape()
                            .stroke(bubble.stroke, lineWidth: bubble.strokeWidth)
                    )
                    .offset(y: bubble.yOffset)
                    .transition(.scale(scale: 0.86).combined(with: .opacity))
            }

            AgentInteractionCaptureView(
                onClick: {
                    store.poke()
                },
                onDragChanged: { translation in
                    guard !store.isPositionLocked else { return }
                    onDragChanged(translation)
                },
                onDragEnded: {
                    guard !store.isPositionLocked else { return }
                    onDragEnded()
                },
                onThreeFingerDragChanged: { translation in
                    guard !store.isPositionLocked else { return }
                    onDragChanged(translation)
                },
                onThreeFingerDragEnded: {
                    guard !store.isPositionLocked else { return }
                    onDragEnded()
                }
            )
            .frame(width: AgentLayout.spriteSize.width, height: AgentLayout.spriteSize.height)
            .position(x: AgentLayout.panelSize.width / 2, y: AgentLayout.panelSize.height - AgentLayout.spriteSize.height / 2)
        }
        .frame(width: AgentLayout.panelSize.width, height: AgentLayout.panelSize.height)
        .contentShape(Rectangle())
        .onChange(of: store.pokeReactionID) { _, _ in
            playPokeReaction()
        }
        .animation(.spring(response: 0.22, dampingFraction: 0.78), value: currentBubble?.text)
        .accessibilityLabel("Pixel Agent")
    }

    private var currentBubble: AgentBubble? {
        if let speechText = store.speechText {
            return .poke(speechText)
        }

        switch store.state {
        case .working, .toolActive:
            return .working
        case .idleVariant:
            switch store.idleVariantKind {
            case .sleepy, .none:
                return .sleepy
            case .gaming:
                return .gaming
            }
        case .hidden, .idle, .completed:
            return nil
        }
    }

    private func playPokeReaction() {
        withAnimation(.easeOut(duration: 0.08)) {
            reactionOffset = CGSize(width: 5, height: -1)
            reactionRotation = 4
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeOut(duration: 0.08)) {
                reactionOffset = CGSize(width: -3, height: 1)
                reactionRotation = -3
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.55)) {
                reactionOffset = .zero
                reactionRotation = 0
            }
        }
    }
}

private struct AgentBubble {
    let text: String
    let background: Color
    let foreground: Color
    let stroke: Color
    let shadow: Color
    let fontSize: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let yOffset: CGFloat
    let strokeWidth: CGFloat
    let shadowRadius: CGFloat

    static let working = AgentBubble(
        text: "工作中勿扰...",
        background: Color(red: 0.08, green: 0.11, blue: 0.12).opacity(0.94),
        foreground: Color(red: 0.67, green: 1.0, blue: 0.72),
        stroke: Color(red: 0.38, green: 0.92, blue: 0.54).opacity(0.95),
        shadow: .black.opacity(0.26),
        fontSize: 13,
        horizontalPadding: 11,
        verticalPadding: 5,
        yOffset: 2,
        strokeWidth: 1,
        shadowRadius: 3
    )

    static let sleepy = AgentBubble(
        text: "瞌睡...",
        background: Color(red: 0.91, green: 0.95, blue: 1.0).opacity(0.98),
        foreground: Color(red: 0.18, green: 0.23, blue: 0.35),
        stroke: Color(red: 0.48, green: 0.62, blue: 0.92).opacity(0.95),
        shadow: Color(red: 0.16, green: 0.20, blue: 0.30).opacity(0.28),
        fontSize: 15,
        horizontalPadding: 13,
        verticalPadding: 6,
        yOffset: 0,
        strokeWidth: 1.5,
        shadowRadius: 4
    )

    static let gaming = AgentBubble(
        text: "摸会儿鱼...",
        background: Color(red: 0.10, green: 0.10, blue: 0.16).opacity(0.95),
        foreground: Color(red: 0.96, green: 0.91, blue: 0.38),
        stroke: Color(red: 0.35, green: 0.76, blue: 1.0).opacity(0.9),
        shadow: .black.opacity(0.26),
        fontSize: 14,
        horizontalPadding: 12,
        verticalPadding: 5,
        yOffset: 1,
        strokeWidth: 1,
        shadowRadius: 3
    )

    static func poke(_ text: String) -> AgentBubble {
        AgentBubble(
            text: text,
            background: .white.opacity(0.96),
            foreground: .black,
            stroke: Color(red: 1.0, green: 0.66, blue: 0.22).opacity(0.85),
            shadow: .black.opacity(0.22),
            fontSize: 14,
            horizontalPadding: 10,
            verticalPadding: 5,
            yOffset: 2,
            strokeWidth: 1,
            shadowRadius: 2
        )
    }
}

private struct SpeechBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let bubbleRect = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: rect.height - 5
        )
        var path = Path(roundedRect: bubbleRect, cornerRadius: 7)
        path.move(to: CGPoint(x: rect.midX - 5, y: bubbleRect.maxY - 1))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX + 6, y: bubbleRect.maxY - 1))
        path.closeSubpath()
        return path
    }
}
