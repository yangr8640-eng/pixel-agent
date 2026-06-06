import Foundation

public enum AgentState: String, Codable, CaseIterable, Equatable, Sendable {
    case hidden
    case idle
    case working
    case toolActive
    case completed
    case idleVariant

    public var animationKey: String {
        switch self {
        case .hidden, .idle:
            "idle"
        case .working:
            "working"
        case .toolActive:
            "toolActive"
        case .completed:
            "completed"
        case .idleVariant:
            "idleVariant"
        }
    }
}
