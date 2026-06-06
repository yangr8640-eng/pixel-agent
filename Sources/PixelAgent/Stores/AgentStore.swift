import Combine
import Foundation
import PixelAgentCore

@MainActor
final class AgentStore: ObservableObject {
    @Published private(set) var state: AgentState = .hidden
    @Published private(set) var isVisible = false
    @Published var isPaused = false
    @Published var isPositionLocked = false
    @Published private(set) var codexIsRunning = false
    @Published private(set) var lastEvent: AgentEvent?
    @Published private(set) var speechText: String?
    @Published private(set) var pokeReactionID = 0
    @Published private(set) var idleVariantKind: IdleVariantKind?

    private var completedTimer: Timer?
    private var idleTimer: Timer?
    private var idleVariantTimer: Timer?
    private var speechTimer: Timer?
    private let completedDuration: TimeInterval
    private let idleVariantDelay: TimeInterval
    private let idleVariantDuration: TimeInterval

    init(
        completedDuration: TimeInterval = 4.0,
        idleVariantDelay: TimeInterval = 60.0,
        idleVariantDuration: TimeInterval = 14.0
    ) {
        self.completedDuration = completedDuration
        self.idleVariantDelay = idleVariantDelay
        self.idleVariantDuration = idleVariantDuration
    }

    var animationKey: String {
        if state == .idleVariant {
            return (idleVariantKind ?? .sleepy).animationKey
        }
        return state.animationKey
    }

    func handle(_ event: AgentEvent) {
        lastEvent = event
        guard let nextState = AgentEventMapper.state(for: event.hookEventName) else {
            return
        }
        setVisible(true)
        transition(to: nextState)
    }

    func setCodexRunning(_ running: Bool) {
        codexIsRunning = running
        if running {
            setVisible(true)
            if state == .hidden {
                transition(to: .idle)
            }
        } else {
            setVisible(false)
            transition(to: .hidden)
        }
    }

    func setVisible(_ visible: Bool) {
        isVisible = visible
        if visible, state == .hidden {
            transition(to: .idle)
        } else if !visible {
            transition(to: .hidden)
        }
    }

    func toggleVisible() {
        setVisible(!isVisible)
    }

    func simulateWorking() {
        setVisible(true)
        transition(to: .working)
    }

    func simulateComplete() {
        setVisible(true)
        transition(to: .completed)
    }

    func simulateSleepy() {
        setVisible(true)
        transition(to: .idleVariant, idleVariantKind: .sleepy)
    }

    func simulateGaming() {
        setVisible(true)
        transition(to: .idleVariant, idleVariantKind: .gaming)
    }

    func poke() {
        setVisible(true)
        speechTimer?.invalidate()
        speechText = "干嘛？"
        pokeReactionID += 1
        speechTimer = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.speechText = nil
            }
        }
    }

    private func transition(to nextState: AgentState, idleVariantKind: IdleVariantKind? = nil) {
        completedTimer?.invalidate()
        completedTimer = nil
        idleTimer?.invalidate()
        idleTimer = nil
        idleVariantTimer?.invalidate()
        idleVariantTimer = nil

        if nextState == .idleVariant {
            self.idleVariantKind = idleVariantKind ?? randomIdleVariant()
        } else {
            self.idleVariantKind = nil
        }
        state = nextState

        switch nextState {
        case .completed:
            completedTimer = Timer.scheduledTimer(withTimeInterval: completedDuration, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.transition(to: .idle)
                }
            }
        case .idle:
            scheduleIdleVariant()
        case .idleVariant:
            scheduleIdleVariantEnd()
        case .hidden, .working, .toolActive:
            break
        }
    }

    private func scheduleIdleVariant() {
        idleTimer = Timer.scheduledTimer(withTimeInterval: idleVariantDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.state == .idle, self.isVisible else { return }
                self.transition(to: .idleVariant)
            }
        }
    }

    private func scheduleIdleVariantEnd() {
        idleVariantTimer = Timer.scheduledTimer(withTimeInterval: idleVariantDuration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.state == .idleVariant, self.isVisible else { return }
                self.transition(to: .idle)
            }
        }
    }

    private func randomIdleVariant() -> IdleVariantKind {
        IdleVariantKind.allCases.randomElement() ?? .sleepy
    }
}
