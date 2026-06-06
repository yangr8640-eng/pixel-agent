import Foundation
import XCTest

final class HookScriptTests: XCTestCase {
    func testHookScriptDropsPromptAndWritesSanitizedEvent() throws {
        let tempHome = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("PixelAgentHookTest-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempHome, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempHome)
        }

        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/pixel_agent_hook.py")
        let promptSecret = "DO_NOT_STORE_THIS_PROMPT"
        let payload = """
        {"hook_event_name":"UserPromptSubmit","session_id":"s1","turn_id":"t1","prompt":"\(promptSecret)"}
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [scriptURL.path]
        process.environment = [
            "HOME": tempHome.path,
            "PATH": "/usr/bin:/bin:/usr/sbin:/sbin"
        ]

        let input = Pipe()
        process.standardInput = input
        try process.run()
        input.fileHandleForWriting.write(Data(payload.utf8))
        try input.fileHandleForWriting.close()
        process.waitUntilExit()

        XCTAssertEqual(process.terminationStatus, 0)

        let eventLog = tempHome
            .appendingPathComponent("Library/Application Support/PixelAgent/events.jsonl")
        let written = try String(contentsOf: eventLog, encoding: .utf8)

        XCTAssertTrue(written.contains("UserPromptSubmit"))
        XCTAssertTrue(written.contains("\"sessionId\":\"s1\""))
        XCTAssertFalse(written.contains(promptSecret))
        XCTAssertFalse(written.contains("\"prompt\""))
    }

    func testStopHookEmitsJSONStdout() throws {
        let tempHome = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("PixelAgentHookStopTest-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempHome, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempHome)
        }

        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/pixel_agent_hook.py")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [scriptURL.path]
        process.environment = [
            "HOME": tempHome.path,
            "PATH": "/usr/bin:/bin:/usr/sbin:/sbin"
        ]

        let input = Pipe()
        let output = Pipe()
        process.standardInput = input
        process.standardOutput = output
        try process.run()
        input.fileHandleForWriting.write(Data(#"{"hook_event_name":"Stop","turn_id":"t1"}"#.utf8))
        try input.fileHandleForWriting.close()
        process.waitUntilExit()

        let stdout = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        XCTAssertEqual(process.terminationStatus, 0)
        XCTAssertEqual(stdout, #"{"continue":true}"#)
    }
}
