import Foundation
import Observation
import Core

enum AppRoute: Hashable { case soloLevels, game(UUID), settings }

@MainActor @Observable final class AppModel {
    let store: ProgressStore
    var path: [AppRoute] = []
    var selectedBand: Band = .easy
    var expandedChapters: Set<Int> = [0]
    var game: GameViewModel?
    var replacementLevel: Int?
    var advancedLevel: Int?
    var tutorialPresented = false
    var tutorialIsFirstRun = false
    var duoPresented = false
    let feedback: FeedbackService

    init(store: ProgressStore) {
        self.store = store
        feedback = FeedbackService { store.state.settings }
        SoundService.shared.setEnabled(store.state.settings.sound)
    }

    /// 浏览状态不写入存档;每次从首页进入按最近一局初始化。
    func showSoloLevels() {
        selectedBand = store.state.solo.map { LevelStore.level(id: $0.levelID).band } ?? .easy
        expandedChapters = [0]
        if let id = store.state.solo?.levelID, id > 100 { expandedChapters.insert((id - 101) / 50) }
        path = [.soloLevels]
    }

    var soloShortcut: (title: String, levelID: Int?, restart: Bool) {
        guard let saved = store.state.solo else { return ("开始闯关 · 简单第 1 关", 1, false) }
        let mode = saved.levelID <= 100 ? "简单" : "进阶"
        if saved.outcome == .win && (saved.levelID == 100 || saved.levelID == 600) {
            return ("\(mode)模式已完成", nil, false)
        }
        let next = saved.outcome == .win
        let retry = saved.outcome != nil && !next
        let id = saved.levelID + (next ? 1 : 0)
        let number = id <= 100 ? id : id - 100
        let action = next ? "下一关" : retry ? "重试" : "继续闯关"
        return ("\(action) · \(mode)第 \(number) 关", id, retry)
    }

    func performSoloShortcut() {
        let shortcut = soloShortcut
        guard let id = shortcut.levelID else { return }
        if shortcut.restart { openLevel(id, restoring: false) }
        else { requestLevel(id) }
    }

    func requestLevel(_ id: Int) {
        guard (1...600).contains(id) else { return }
        if let saved = store.state.solo, saved.levelID != id, saved.outcome == nil {
            replacementLevel = id
        } else { prepareLevel(id) }
    }
    func confirmReplacement() {
        guard let id = replacementLevel else { return }
        replacementLevel = nil
        prepareLevel(id)
    }
    private func prepareLevel(_ id: Int) {
        if id > 100 && !store.state.settings.advancedHelpSeen { advancedLevel = id }
        else { openLevel(id) }
    }
    func confirmAdvancedHelp() {
        guard let id = advancedLevel else { return }
        store.updateSettings { $0.advancedHelpSeen = true }
        advancedLevel = nil
        openLevel(id)
    }
    func openLevel(_ id: Int, restoring: Bool = true) {
        game?.pause()
        let saved = restoring ? store.state.solo.flatMap { $0.levelID == id ? $0 : nil } : nil
        selectedBand = LevelStore.level(id: id).band
        if id > 100 { expandedChapters.insert((id - 101) / 50) }
        let model = GameViewModel(configuration: .solo(LevelStore.level(id: id)), snapshot: saved)
        model.feedback = { [weak self] in self?.feedback.play($0) }
        model.onChange = { [weak self, weak model] in
            guard let self, let model, self.game === model, let snapshot = model.snapshot() else { return }
            self.store.save(snapshot)
        }
        game = model
        if let snapshot = model.snapshot() { store.save(snapshot) }
        path.removeAll { if case .game = $0 { true } else { false } }
        if !path.contains(.soloLevels) { path = [.soloLevels] }
        path.append(.game(model.roundID))
    }
    func leaveGame() {
        game?.pause()
        game = nil
        if case .game = path.last { path.removeLast() }
    }
    func selectLevels() {
        let band = game?.configuration.levelID.map { LevelStore.level(id: $0).band } ?? .easy
        game?.pause()
        game = nil
        selectedBand = band
        path = [.soloLevels]
    }
    func nextLevel() {
        guard let id = game?.configuration.levelID else { return }
        if id == 100 || id == 600 { selectLevels() }
        else { openLevel(id + 1) }
    }
    func showTutorial(firstRun: Bool) {
        tutorialIsFirstRun = firstRun
        tutorialPresented = true
    }
    func endTutorial(completed: Bool) {
        if completed { store.finishTutorial(firstRun: tutorialIsFirstRun) }
        else { store.updateSettings { $0.tutorialSeen = true } }
        tutorialPresented = false
        if completed && tutorialIsFirstRun { requestLevel(2) }
    }
}
