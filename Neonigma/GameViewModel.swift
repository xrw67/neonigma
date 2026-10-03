import Foundation
import Observation
import Core

/// 规则结果与答案揭示、反馈动画分别管理。
enum GameOutcome: String, Codable { case win, lose, timeout }
enum HintMode: String, CaseIterable { case direct, indirect }

struct GameConfiguration {
    enum Kind { case solo, duo, tutorial }
    let kind: Kind
    let levelID: Int?
    let code: [PegColor]
    let clue: [PegColor]?
    let hints: HintMode
    let timeLimit: TimeInterval?
    var maxGuesses: Int { clue == nil ? 7 : 6 }
    var title: String { levelID.map { LevelStore.level(id: $0).displayID } ?? "双人对战" }

    static func solo(_ level: Level) -> Self {
        Self(kind: .solo, levelID: level.id, code: level.code, clue: level.clue,
             hints: level.band == .easy ? .direct : .indirect, timeLimit: nil)
    }
    static func tutorial(_ level: Level) -> Self {
        Self(kind: .tutorial, levelID: level.id, code: level.code, clue: level.clue, hints: .direct, timeLimit: nil)
    }
    static func duo(code: [PegColor], hints: HintMode, seconds: TimeInterval?) -> Self? {
        guard code.count == 4, Set(code).count == 4 else { return nil }
        return Self(kind: .duo, levelID: nil, code: code, clue: nil, hints: hints, timeLimit: seconds)
    }
}

@MainActor @Observable final class GameViewModel {
    struct RowState {
        let guess: [PegColor]
        let evaluation: Evaluation
        var revealed: Int = 4
    }
    let configuration: GameConfiguration
    private(set) var roundID: UUID
    private(set) var rows: [RowState] = []
    private(set) var current: [PegColor?] = Array(repeating: nil, count: 4)
    private(set) var selected = 0
    private(set) var locked = false
    private(set) var outcome: GameOutcome?
    private(set) var answerRevealed = false
    private(set) var elapsed: TimeInterval = 0
    private(set) var running = false
    var reduceMotion = false

    @ObservationIgnored private let now: () -> TimeInterval
    @ObservationIgnored private var startedAt: TimeInterval?
    @ObservationIgnored private var accumulated: TimeInterval = 0
    @ObservationIgnored private var animationTask: Task<Void, Never>?
    @ObservationIgnored private var animationGeneration = UUID()
    @ObservationIgnored private var lastHeartbeat: Int?
    @ObservationIgnored var onChange: (() -> Void)?
    @ObservationIgnored var feedback: (FeedbackEvent) -> Void = { _ in }

    init(configuration: GameConfiguration, snapshot: SoloSnapshot? = nil,
         now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) {
        self.configuration = configuration
        self.now = now
        self.roundID = snapshot?.roundID ?? UUID()
        if let clue = configuration.clue {
            rows = [RowState(guess: clue, evaluation: CodeBreakerEngine.evaluate(code: configuration.code, guess: clue))]
        }
        if let snapshot {
            rows += snapshot.guesses.map { RowState(guess: $0, evaluation: CodeBreakerEngine.evaluate(code: configuration.code, guess: $0)) }
            current = snapshot.current
            selected = snapshot.selected
            accumulated = snapshot.elapsed
            elapsed = accumulated
            outcome = snapshot.outcome
            answerRevealed = snapshot.answerRevealed
        }
    }

    var guessesUsed: Int { rows.count - (configuration.clue == nil ? 0 : 1) }
    var maxGuesses: Int { configuration.maxGuesses }
    var isEasy: Bool { configuration.hints == .direct }
    var canEdit: Bool { running && !locked && outcome == nil }
    var canSubmit: Bool { canEdit && current.allSatisfy { $0 != nil } }
    var answer: [PegColor] { configuration.code }
    var remaining: TimeInterval? { configuration.timeLimit.map { max(0, $0 - elapsed) } }
    var readyForResult: Bool { outcome != nil && !locked }

    func resume() {
        guard outcome == nil, !running else { return }
        startedAt = now()
        running = true
    }

    func pause() {
        refreshElapsed()
        accumulated = elapsed
        startedAt = nil
        running = false
        finishAnimation()
        onChange?()
    }

    private func refreshElapsed() {
        elapsed = accumulated + (startedAt.map { max(0, now() - $0) } ?? 0)
    }

    func tick() {
        guard running, outcome == nil else { return }
        refreshElapsed()
        if let remaining {
            if remaining <= 0 {
                finishAnimation()
                finish(.timeout)
                onChange?()
            } else if remaining <= 30 {
                let second = Int(ceil(remaining))
                if lastHeartbeat != second {
                    lastHeartbeat = second
                    feedback(.heartbeat)
                }
            }
        }
    }

    func select(_ index: Int) {
        guard canEdit, (0..<4).contains(index) else { return }
        selected = index
        feedback(.select)
        changed()
    }
    func fill(_ color: PegColor) {
        guard canEdit else { return }
        current[selected] = color
        feedback(.place)
        for k in 1...4 {
            let next = (selected + k) % 4
            if current[next] == nil { selected = next; break }
        }
        changed()
    }
    func clearCell(_ index: Int) {
        guard canEdit, (0..<4).contains(index) else { return }
        current[index] = nil
        selected = index
        changed()
    }
    func cycle(_ index: Int, direction: Int) {
        guard canEdit, (0..<4).contains(index) else { return }
        selected = index
        let base = current[index]?.rawValue ?? (direction > 0 ? -1 : 0)
        current[index] = PegColor(rawValue: (base + direction + 7) % 7)
        feedback(.place)
        changed()
    }
    func clearCurrent() {
        guard canEdit else { return }
        current = Array(repeating: nil, count: 4)
        selected = 0
        changed()
    }

    func submit() {
        tick()
        guard canSubmit else { return }
        let guess = current.compactMap { $0 }
        let evaluation = CodeBreakerEngine.evaluate(code: answer, guess: guess)
        rows.append(RowState(guess: guess, evaluation: evaluation, revealed: reduceMotion ? 4 : 0))
        current = Array(repeating: nil, count: 4)
        selected = 0
        locked = !reduceMotion
        feedback(.submit)
        // 提交时决定胜负,截止前的正确答案不因动画耗时失效。
        if evaluation.greens == 4 { finish(.win) }
        else if guessesUsed == maxGuesses { finish(.lose) }
        changed()
        guard !reduceMotion else { return }
        let generation = UUID()
        animationGeneration = generation
        let rowIndex = rows.count - 1
        animationTask = Task { [weak self] in
            for step in 1...4 {
                do { try await Task.sleep(for: .milliseconds(90)) } catch { return }
                guard let self, self.animationGeneration == generation, self.rows.indices.contains(rowIndex) else { return }
                self.rows[rowIndex].revealed = step
                self.feedback(.hint)
            }
            guard let self, self.animationGeneration == generation else { return }
            self.locked = false
            self.animationTask = nil
            self.onChange?()
        }
    }

    private func finish(_ result: GameOutcome) {
        guard outcome == nil else { return }
        refreshElapsed()
        accumulated = elapsed
        startedAt = nil
        running = false
        outcome = result
        feedback(result == .win ? .win : .lose)
    }
    private func changed() { refreshElapsed(); onChange?() }

    func finishAnimation() {
        animationGeneration = UUID()
        animationTask?.cancel()
        animationTask = nil
        for index in rows.indices { rows[index].revealed = 4 }
        locked = false
    }
    func revealAnswer(allowed: Bool) {
        guard allowed, outcome == .lose || outcome == .timeout else { return }
        answerRevealed = true
        onChange?()
    }
    func restart() {
        finishAnimation()
        roundID = UUID()
        rows = configuration.clue.map { [RowState(guess: $0, evaluation: CodeBreakerEngine.evaluate(code: answer, guess: $0))] } ?? []
        current = Array(repeating: nil, count: 4)
        selected = 0
        outcome = nil
        answerRevealed = false
        accumulated = 0
        elapsed = 0
        running = false
        startedAt = nil
        lastHeartbeat = nil
        resume()
        onChange?()
    }
    func snapshot() -> SoloSnapshot? {
        guard configuration.kind == .solo, let id = configuration.levelID else { return nil }
        refreshElapsed()
        return SoloSnapshot(levelID: id, roundID: roundID, guesses: rows.dropFirst().map(\.guess),
                            current: current, selected: selected, elapsed: elapsed,
                            outcome: outcome, answerRevealed: answerRevealed)
    }
}
