import Foundation

struct AnimationManifest: Decodable {
    let frameWidth: CGFloat
    let frameHeight: CGFloat
    let columns: Int
    let animations: [String: AnimationSpec]
}

struct AnimationSpec: Decodable {
    let row: Int
    let frames: [Int]
    let fps: Double
    let loops: Bool
}
