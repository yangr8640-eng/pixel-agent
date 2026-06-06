import ImageIO
import PixelAgentCore
import SwiftUI

struct SpriteAnimatorView: View {
    @ObservedObject var store: AgentStore

    @State private var manifest: AnimationManifest?
    @State private var atlas: CGImage?
    @State private var startedAt = Date()
    @State private var frozenFrame = 0

    private let ticker = Timer.publish(every: 1.0 / 12.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            if let atlas,
               let manifest,
               let spec = manifest.animations[store.animationKey],
               let frameImage = frameImage(atlas: atlas, manifest: manifest, spec: spec) {
                Image(decorative: frameImage, scale: 1, orientation: .up)
                    .resizable()
                    .interpolation(.none)
                    .antialiased(false)
                    .aspectRatio(1, contentMode: .fit)
            } else {
                ProceduralAgentView(state: store.state, frame: frozenFrame)
            }
        }
        .frame(width: AgentLayout.spriteSize.width, height: AgentLayout.spriteSize.height)
        .drawingGroup(opaque: false, colorMode: .nonLinear)
        .onAppear(perform: loadAssets)
        .onChange(of: store.animationKey) { _, _ in
            startedAt = Date()
            frozenFrame = 0
        }
        .onReceive(ticker) { _ in
            guard !store.isPaused else { return }
            frozenFrame += 1
        }
    }

    private func currentFrame(spec: AnimationSpec) -> Int {
        if store.isPaused {
            return spec.frames[frozenFrame % max(spec.frames.count, 1)]
        }
        let elapsed = Date().timeIntervalSince(startedAt)
        let index = Int(elapsed * spec.fps)
        if spec.loops {
            return spec.frames[index % max(spec.frames.count, 1)]
        }
        return spec.frames[min(index, spec.frames.count - 1)]
    }

    private func frameImage(
        atlas: CGImage,
        manifest: AnimationManifest,
        spec: AnimationSpec
    ) -> CGImage? {
        atlas.cropping(to: sourceRect(
            manifest: manifest,
            spec: spec,
            frame: currentFrame(spec: spec)
        ))
    }

    private func sourceRect(manifest: AnimationManifest, spec: AnimationSpec, frame: Int) -> CGRect {
        let x = CGFloat(frame) * manifest.frameWidth
        let y = CGFloat(spec.row) * manifest.frameHeight
        return CGRect(x: x, y: y, width: manifest.frameWidth, height: manifest.frameHeight)
    }

    private func loadAssets() {
        if manifest == nil,
           let url = Bundle.module.url(
                forResource: "animations",
                withExtension: "json"
           ),
           let data = try? Data(contentsOf: url) {
            manifest = try? JSONDecoder().decode(AnimationManifest.self, from: data)
        }

        if atlas == nil,
           let url = Bundle.module.url(
                forResource: "pixel-agent-sprite-atlas",
                withExtension: "png"
           ),
           let source = CGImageSourceCreateWithURL(url as CFURL, nil) {
            atlas = CGImageSourceCreateImageAtIndex(source, 0, nil)
        }
    }
}
