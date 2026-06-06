import PixelAgentCore
import XCTest

final class AgentEventMapperTests: XCTestCase {
    func testMapsCodexLifecycleEventsToAgentStates() {
        XCTAssertEqual(AgentEventMapper.state(for: "SessionStart"), .idle)
        XCTAssertEqual(AgentEventMapper.state(for: "UserPromptSubmit"), .working)
        XCTAssertEqual(AgentEventMapper.state(for: "PreToolUse"), .toolActive)
        XCTAssertEqual(AgentEventMapper.state(for: "PermissionRequest"), .toolActive)
        XCTAssertEqual(AgentEventMapper.state(for: "PostToolUse"), .working)
        XCTAssertEqual(AgentEventMapper.state(for: "Stop"), .completed)
    }

    func testIgnoresUnknownEvents() {
        XCTAssertNil(AgentEventMapper.state(for: "PostCompact"))
        XCTAssertNil(AgentEventMapper.state(for: "Unknown"))
    }
}
