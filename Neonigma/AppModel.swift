import Foundation
import Observation
import Core

enum AppRoute: Hashable { case levels(Band), game(UUID), settings }

@MainActor @Observable final class AppModel {
    let store: ProgressStore
    var path: [AppRoute] = []
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
    func openLevel(_ id: Int) {
        game?.pause()
        let saved = store.state.solo.flatMap { $0.levelID == id ? $0 : nil }
        let model = GameViewModel(configuration: .solo(LevelStore.level(id: id)), snapshot: saved)
        model.feedback = { [weak self] in self?.feedback.play($0) }
        model.onChange = { [weak self, weak model] in
            guard let self, let snapshot = model?.snapshot() else { return }
            self.store.save(snapshot)
        }
        game = model
        if let snapshot = model.snapshot() { store.save(snapshot) }
        path.removeAll { if case .game = $0 { true } else { false } }
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
        path = [.levels(band)]
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
