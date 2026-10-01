import Foundation
import Observation
import Core

/// 一局对局的状态机(PRD §3 / §4.2、§4.4)。
/// 行结构:第 1 行起始线索(预判定)+ 至多 6 次玩家猜测;已提交行不可撤回(FR-P4)。
@MainActor @Observable final class GameViewModel {

    struct RowState {
        let guess: [PegColor]
        let evaluation: Evaluation
        var revealed: Int = 4
    }

    enum Outcome: Equatable {
        case win(stars: Int)
        case lose
        case revealed
    }

    let level: Level
    private(set) var rows: [RowState]
    private(set) var current: [PegColor?] = [nil, nil, nil, nil]
    private(set) var selected: Int = 0
    /// 提示动画播放期间冻结输入(FR-P8)。
    private(set) var locked = false
    private(set) var outcome: Outcome?

    private let sounds: SoundService

    init(level: Level, sounds: SoundService = .shared) {
        self.level = level
        self.sounds = sounds
        // FR-S1:起始线索行立即给出判定
        self.rows = [RowState(guess: level.clue,
                              evaluation: CodeBreakerEngine.evaluate(code: level.code, guess: level.clue))]
    }

    // MARK: 派生状态

    var guessesUsed: Int { rows.count - 1 }
    var maxGuesses: Int { 6 }
    var isEasy: Bool { level.band == .easy }
    var canSubmit: Bool { !locked && outcome == nil && current.allSatisfy { $0 != nil } }
    var answer: [PegColor] { level.code }

    // MARK: 交互(FR-P1 / FR-P2)

    func select(_ index: Int) {
        guard !locked, outcome == nil else { return }
        selected = index
        sounds.play(.select)
    }

    func fill(_ color: PegColor) {
        guard !locked, outcome == nil else { return }
        current[selected] = color
        sounds.play(.place)
        // 自动跳到下一个空格
        for k in 1...4 {
            let idx = (selected + k) % 4
            if current[idx] == nil { selected = idx; return }
        }
    }

    func clearCurrent() {
        guard !locked, outcome == nil else { return }
        current = [nil, nil, nil, nil]
        selected = 0
    }

    // MARK: 提交(FR-P3:提交即锁定 + 逐点点亮)

    func submit() async {
        guard canSubmit, let guess = current.compactMap({ $0 }) as [PegColor]?, guess.count == 4 else { return }
        let evaluation = CodeBreakerEngine.evaluate(code: level.code, guess: guess)
        rows.append(RowState(guess: guess, evaluation: evaluation, revealed: 0))
        current = [nil, nil, nil, nil]
        selected = 0
        locked = true
        sounds.play(.submit)

        let rowIndex = rows.count - 1
        let litCount = isEasy ? 4 : evaluation.greens + evaluation.whites
        for step in 1...max(litCount, 1) {
            try? await Task.sleep(for: .milliseconds(90))
            guard !Task.isCancelled else { return }
            rows[rowIndex].revealed = step
        }
        locked = false

        if evaluation.greens == 4 {
            outcome = .win(stars: Self.stars(for: rows.count - 1))
            sounds.play(.win)
        } else if rows.count - 1 >= maxGuesses {
            outcome = .lose   // 第 7 行提示展示完毕仍未破译(§3.5)
            sounds.play(.lose)
        }
    }

    // MARK: 结算(FR-S5:失败默认可查看答案,Q3 已定稿)

    func revealAnswer() {
        guard outcome == .lose else { return }
        outcome = .revealed
    }

    /// 原地重开本关(FR-S3:重置为只有起始线索的初始态)。
    func restart() {
        rows = [RowState(guess: level.clue,
                         evaluation: CodeBreakerEngine.evaluate(code: level.code, guess: level.clue))]
        current = [nil, nil, nil, nil]
        selected = 0
        locked = false
        outcome = nil
    }

    /// FR-S4:按猜测次数给星(不含起始线索行)。
    static func stars(for guesses: Int) -> Int {
        guesses <= 2 ? 3 : guesses <= 4 ? 2 : 1
    }
}
