import Foundation
import PixelAgentCore

@MainActor
final class EventLogService {
    var onEvent: ((AgentEvent) -> Void)?

    private let eventLogURL: URL
    private var timer: Timer?
    private var readOffset: UInt64 = 0
    private let decoder: JSONDecoder

    init(eventLogURL: URL = AppPaths.eventLog) {
        self.eventLogURL = eventLogURL
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: value) {
                return date
            }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO8601 timestamp: \(value)"
            )
        }
    }

    func start() {
        do {
            try AppPaths.ensureApplicationSupportDirectory()
            if !FileManager.default.fileExists(atPath: eventLogURL.path) {
                FileManager.default.createFile(atPath: eventLogURL.path, contents: nil)
            }
            readOffset = currentFileSize()
        } catch {
            NSLog("PixelAgent failed to prepare event log: \(error)")
        }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.readNewEvents()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func readNewEvents() {
        do {
            let size = currentFileSize()
            if size < readOffset {
                readOffset = 0
            }
            guard size > readOffset else { return }

            let handle = try FileHandle(forReadingFrom: eventLogURL)
            try handle.seek(toOffset: readOffset)
            let data = try handle.readToEnd() ?? Data()
            readOffset = try handle.offset()
            try handle.close()

            guard let text = String(data: data, encoding: .utf8) else { return }
            for line in text.split(whereSeparator: \.isNewline) {
                guard let lineData = String(line).data(using: .utf8) else { continue }
                if let event = try? decoder.decode(AgentEvent.self, from: lineData) {
                    onEvent?(event)
                }
            }
        } catch {
            NSLog("PixelAgent failed to read event log: \(error)")
        }
    }

    private func currentFileSize() -> UInt64 {
        let attributes = try? FileManager.default.attributesOfItem(atPath: eventLogURL.path)
        return attributes?[.size] as? UInt64 ?? 0
    }
}
