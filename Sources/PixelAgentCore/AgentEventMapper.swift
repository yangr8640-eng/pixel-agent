import Foundation

public enum AgentEventMapper {
    public static func state(for eventName: String) -> AgentState? {
        switch eventName {
        case "SessionStart":
            .idle
        case "UserPromptSubmit":
            .working
        case "PreToolUse", "PermissionRequest":
            .toolActive
        case "PostToolUse":
            .working
        case "Stop":
            .completed
        default:
            nil
        }
    }
}
