import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = AgentStore()
    private let eventLogService = EventLogService()
    private let processMonitor = CodexProcessMonitor()
    private var windowController: AgentWindowController?
    private var statusItem: NSStatusItem?
    private var cancellables: Set<AnyCancellable> = []

    private lazy var hookInstaller: HookInstaller? = {
        guard let scriptURL = Bundle.module.url(
            forResource: "pixel_agent_hook",
            withExtension: "py"
        ) else {
            return nil
        }
        return HookInstaller(scriptURL: scriptURL)
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        windowController = AgentWindowController(store: store)
        configureStatusItem()
        bindStore()
        configureServices()
    }

    func applicationWillTerminate(_ notification: Notification) {
        eventLogService.stop()
        processMonitor.stop()
    }

    private func bindStore() {
        store.$isVisible
            .removeDuplicates()
            .sink { [weak self] visible in
                guard let self else { return }
                if visible {
                    self.windowController?.show()
                } else {
                    self.windowController?.hide()
                }
                self.rebuildMenu()
            }
            .store(in: &cancellables)

        store.$isPaused
            .merge(with: store.$isPositionLocked)
            .sink { [weak self] _ in self?.rebuildMenu() }
            .store(in: &cancellables)
    }

    private func configureServices() {
        eventLogService.onEvent = { [weak self] event in
            Task { @MainActor in
                self?.store.handle(event)
            }
        }
        eventLogService.start()

        processMonitor.onChange = { [weak self] running in
            Task { @MainActor in
                self?.store.setCodexRunning(running)
            }
        }
        processMonitor.start()
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "PX"
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.addItem(menuItem(
            title: store.isVisible ? "Hide Pixel Agent" : "Show Pixel Agent",
            action: #selector(toggleVisible)
        ))
        menu.addItem(menuItem(
            title: "Lock Position",
            action: #selector(togglePositionLock),
            state: store.isPositionLocked
        ))
        menu.addItem(menuItem(
            title: "Pause Animation",
            action: #selector(togglePause),
            state: store.isPaused
        ))
        menu.addItem(.separator())
        menu.addItem(menuItem(
            title: "Start at Login",
            action: #selector(toggleStartAtLogin),
            state: LaunchAtLoginService.isEnabled
        ))
        menu.addItem(menuItem(
            title: "Install Codex Hooks",
            action: #selector(installHooks),
            enabled: hookInstaller != nil
        ))
        menu.addItem(menuItem(
            title: "Uninstall Hooks",
            action: #selector(uninstallHooks),
            enabled: hookInstaller != nil
        ))
        menu.addItem(.separator())
        menu.addItem(menuItem(title: "Debug: Work", action: #selector(debugWork)))
        menu.addItem(menuItem(title: "Debug: Complete", action: #selector(debugComplete)))
        menu.addItem(menuItem(title: "Debug: Sleepy", action: #selector(debugSleepy)))
        menu.addItem(menuItem(title: "Debug: Gaming", action: #selector(debugGaming)))
        menu.addItem(.separator())
        menu.addItem(menuItem(title: "Quit", action: #selector(quit)))
        statusItem?.menu = menu
    }

    private func menuItem(
        title: String,
        action: Selector,
        state: Bool = false,
        enabled: Bool = true
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = state ? .on : .off
        item.isEnabled = enabled
        return item
    }

    @objc private func toggleVisible() {
        store.toggleVisible()
    }

    @objc private func togglePositionLock() {
        store.isPositionLocked.toggle()
        rebuildMenu()
    }

    @objc private func togglePause() {
        store.isPaused.toggle()
        rebuildMenu()
    }

    @objc private func toggleStartAtLogin() {
        do {
            try LaunchAtLoginService.setEnabled(!LaunchAtLoginService.isEnabled)
            rebuildMenu()
        } catch {
            showAlert(title: "Start at Login Failed", message: error.localizedDescription)
        }
    }

    @objc private func installHooks() {
        guard let hookInstaller else { return }
        let alert = NSAlert()
        alert.messageText = "Install Codex Hooks?"
        alert.informativeText = "Pixel Agent will add status-only hooks to ~/.codex/hooks.json and create a backup first. User prompts are not stored."
        alert.addButton(withTitle: "Install")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        do {
            try hookInstaller.install()
            showAlert(
                title: "Hooks Installed",
                message: "Open /hooks in Codex if it asks you to review and trust the new hook definitions."
            )
        } catch {
            showAlert(title: "Hook Install Failed", message: error.localizedDescription)
        }
    }

    @objc private func uninstallHooks() {
        guard let hookInstaller else { return }
        do {
            try hookInstaller.uninstall()
            showAlert(title: "Hooks Removed", message: "Pixel Agent hooks were removed after backing up hooks.json.")
        } catch {
            showAlert(title: "Hook Removal Failed", message: error.localizedDescription)
        }
    }

    @objc private func debugWork() {
        store.simulateWorking()
    }

    @objc private func debugComplete() {
        store.simulateComplete()
    }

    @objc private func debugSleepy() {
        store.simulateSleepy()
    }

    @objc private func debugGaming() {
        store.simulateGaming()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }
}
