import Foundation

struct HookInstaller {
    private let hooksURL: URL
    private let scriptURL: URL
    private let marker = "Pixel Agent sync"

    init(
        hooksURL: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/hooks.json"),
        scriptURL: URL
    ) {
        self.hooksURL = hooksURL
        self.scriptURL = scriptURL
    }

    var isInstalled: Bool {
        guard
            let data = try? Data(contentsOf: hooksURL),
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let hooks = root["hooks"] as? [String: Any]
        else {
            return false
        }

        return hooks.values.contains { value in
            guard let groups = value as? [[String: Any]] else { return false }
            return groups.contains(where: groupContainsPixelAgent)
        }
    }

    func install() throws {
        try FileManager.default.createDirectory(
            at: hooksURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try backupExistingFile()

        var root = try loadRootObject()
        var hooks = root["hooks"] as? [String: Any] ?? [:]

        for event in HookEvent.allCases {
            var groups = hooks[event.rawValue] as? [[String: Any]] ?? []
            groups.removeAll(where: groupContainsPixelAgent)
            groups.append(group(for: event))
            hooks[event.rawValue] = groups
        }

        root["hooks"] = hooks
        try write(root: root)
    }

    func uninstall() throws {
        guard FileManager.default.fileExists(atPath: hooksURL.path) else { return }
        try backupExistingFile()

        var root = try loadRootObject()
        var hooks = root["hooks"] as? [String: Any] ?? [:]

        for event in HookEvent.allCases {
            guard var groups = hooks[event.rawValue] as? [[String: Any]] else { continue }
            groups.removeAll(where: groupContainsPixelAgent)
            if groups.isEmpty {
                hooks.removeValue(forKey: event.rawValue)
            } else {
                hooks[event.rawValue] = groups
            }
        }

        root["hooks"] = hooks
        try write(root: root)
    }

    private func loadRootObject() throws -> [String: Any] {
        guard FileManager.default.fileExists(atPath: hooksURL.path) else {
            return ["hooks": [:]]
        }

        let data = try Data(contentsOf: hooksURL)
        guard !data.isEmpty else {
            return ["hooks": [:]]
        }

        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw HookInstallerError.invalidHooksFile
        }
        return object
    }

    private func write(root: [String: Any]) throws {
        let data = try JSONSerialization.data(
            withJSONObject: root,
            options: [.prettyPrinted, .sortedKeys]
        )
        try data.write(to: hooksURL, options: .atomic)
    }

    private func backupExistingFile() throws {
        guard FileManager.default.fileExists(atPath: hooksURL.path) else { return }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let timestamp = formatter.string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let backupURL = hooksURL.deletingLastPathComponent()
            .appendingPathComponent("hooks.pixel-agent-backup-\(timestamp)-\(UUID().uuidString).json")
        try FileManager.default.copyItem(at: hooksURL, to: backupURL)
    }

    private func group(for event: HookEvent) -> [String: Any] {
        [
            "matcher": event.matcher,
            "hooks": [
                [
                    "type": "command",
                    "command": "/usr/bin/python3 \(shellQuoted(scriptURL.path))",
                    "statusMessage": marker
                ]
            ]
        ]
    }

    private func groupContainsPixelAgent(_ group: [String: Any]) -> Bool {
        guard let handlers = group["hooks"] as? [[String: Any]] else { return false }
        return handlers.contains { handler in
            let command = handler["command"] as? String ?? ""
            let statusMessage = handler["statusMessage"] as? String ?? ""
            return statusMessage == marker || command.contains("pixel_agent_hook.py")
        }
    }

    private func shellQuoted(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

private enum HookEvent: String, CaseIterable {
    case sessionStart = "SessionStart"
    case userPromptSubmit = "UserPromptSubmit"
    case preToolUse = "PreToolUse"
    case permissionRequest = "PermissionRequest"
    case postToolUse = "PostToolUse"
    case stop = "Stop"

    var matcher: String {
        switch self {
        case .sessionStart:
            "startup|resume"
        case .userPromptSubmit, .stop:
            "*"
        case .preToolUse, .permissionRequest, .postToolUse:
            "*"
        }
    }
}

enum HookInstallerError: LocalizedError {
    case invalidHooksFile

    var errorDescription: String? {
        "The existing hooks.json is not a JSON object."
    }
}
