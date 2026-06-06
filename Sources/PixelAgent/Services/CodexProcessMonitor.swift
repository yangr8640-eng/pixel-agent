import AppKit
import Foundation

@MainActor
final class CodexProcessMonitor {
    var onChange: ((Bool) -> Void)?

    private var timer: Timer?
    private var lastValue: Bool?

    func start() {
        scan()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.scan()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func scan() {
        let running = NSWorkspace.shared.runningApplications.contains { app in
            let name = (app.localizedName ?? app.executableURL?.lastPathComponent ?? "").lowercased()
            let bundleIdentifier = (app.bundleIdentifier ?? "").lowercased()
            return name == "codex"
                || name.hasPrefix("codex ")
                || bundleIdentifier.contains(".codex")
                || bundleIdentifier.contains("openai.codex")
        }

        guard running != lastValue else { return }
        lastValue = running
        onChange?(running)
    }
}
