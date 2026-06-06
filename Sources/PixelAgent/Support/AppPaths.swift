import Foundation

enum AppPaths {
    static var applicationSupportDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PixelAgent", isDirectory: true)
    }

    static var eventLog: URL {
        applicationSupportDirectory.appendingPathComponent("events.jsonl")
    }

    static func ensureApplicationSupportDirectory() throws {
        try FileManager.default.createDirectory(
            at: applicationSupportDirectory,
            withIntermediateDirectories: true
        )
    }
}
