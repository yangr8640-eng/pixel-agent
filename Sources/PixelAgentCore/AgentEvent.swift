import Foundation

public struct AgentEvent: Codable, Equatable, Sendable {
    public var timestamp: Date
    public var hookEventName: String
    public var sessionId: String?
    public var turnId: String?
    public var toolName: String?
    public var source: String

    public init(
        timestamp: Date,
        hookEventName: String,
        sessionId: String? = nil,
        turnId: String? = nil,
        toolName: String? = nil,
        source: String
    ) {
        self.timestamp = timestamp
        self.hookEventName = hookEventName
        self.sessionId = sessionId
        self.turnId = turnId
        self.toolName = toolName
        self.source = source
    }
}
