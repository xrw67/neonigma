import Foundation
import SwiftData
import Testing
import Core
@testable import Neonigma

@Suite(.serialized) @MainActor struct M2Tests {
    private let code: [PegColor] = [.red, .green, .blue, .yellow]
    private func solo(now: @escaping () -> TimeInterval = { 0 }) -> GameViewModel {
        GameViewModel(configuration: .solo(Level(id: 1, band: .easy, code: code, clue: [.white, .orange, .purple, .blue])), now: now)
    }
    private func enter(_ vm: GameViewModel, _ colors: [PegColor]) {
        vm.clearCurrent()
        for i in 0..<4 { vm.select(i); vm.fill(colors[i]) }
    }
    private func snapshot(id: Int = 1, outcome: GameOutcome? = nil) -> SoloSnapshot {
        SoloSnapshot(levelID: id, roundID: UUID(), guesses: [code], current: [nil, .blue, nil, nil], selected: 1, elapsed: 12, outcome: outcome, answerRevealed: false)
    }

    @Test func soloAndDuoAttemptLimits() {
        let single = solo()
        single.reduceMotion = true
        single.resume()
        for _ in 0..<6 { enter(single, [.white, .white, .white, .white]); single.submit() }
        #expect(single.outcome == .lose)
        #expect(single.rows.count == 7)
        #expect(!single.canSubmit)
        let duo = GameViewModel(configuration: GameConfiguration.duo(code: code, hints: .indirect, seconds: nil)!)
        duo.reduceMotion = true
        duo.resume()
        for _ in 0..<6 { enter(duo, [.white, .white, .white, .white]); duo.submit() }
        #expect(duo.outcome == nil)
        enter(duo, code); duo.submit()
        #expect(duo.outcome == .win)
        #expect(duo.guessesUsed == 7)
        #expect(duo.snapshot() == nil)
    }

    @Test func duplicateSetupRejectedButGuessAllowed() {
        #expect(GameConfiguration.duo(code: [.red, .red, .blue, .yellow], hints: .direct, seconds: 60) == nil)
        #expect(GameConfiguration.duo(code: [.red], hints: .direct, seconds: 60) == nil)
        let vm = solo(); vm.resume()
        enter(vm, [.blue, .blue, .white, .white])
        #expect(vm.canSubmit)
        vm.submit()
        #expect(vm.rows.last?.evaluation.greens == 0)
        #expect(vm.rows.last?.evaluation.whites == 1)
        vm.finishAnimation()
    }

    @Test func clockPausesAndResumesWithoutCountingBackground() {
        var time = 0.0
        let vm = GameViewModel(configuration: GameConfiguration.duo(code: code, hints: .direct, seconds: 60)!, now: { time })
        vm.resume(); time = 12; vm.tick(); vm.pause()
        time = 300; vm.tick()
        #expect(vm.remaining == 48)
        #expect(!vm.canEdit)
        vm.resume(); time = 348; vm.tick()
        #expect(vm.outcome == .timeout)
        #expect(vm.remaining == 0)
        #expect(!vm.running && !vm.canEdit)
    }

    @Test func heartbeatOncePerSecondOnlyWhenActive() {
        var time = 0.0
        var beats = 0
        let vm = GameViewModel(configuration: GameConfiguration.duo(code: code, hints: .direct, seconds: 60)!, now: { time })
        vm.feedback = { if $0 == .heartbeat { beats += 1 } }
        vm.resume(); time = 29; vm.tick(); #expect(beats == 0)
        time = 30; vm.tick(); vm.tick(); #expect(beats == 1)
        time = 31; vm.tick(); #expect(beats == 2)
        vm.pause(); time = 40; vm.tick(); #expect(beats == 2)
    }

    @Test func deadlineIsCheckedBeforeSubmission() {
        var time = 0.0
        let vm = GameViewModel(configuration: GameConfiguration.duo(code: code, hints: .direct, seconds: 60)!, now: { time })
        vm.resume(); enter(vm, code); time = 60; vm.submit()
        #expect(vm.outcome == .timeout)
        #expect(vm.rows.isEmpty)
    }

    @Test func winningBeforeDeadlineSurvivesAnimation() async throws {
        var time = 0.0
        let vm = GameViewModel(configuration: GameConfiguration.duo(code: code, hints: .direct, seconds: 60)!, now: { time })
        vm.resume(); enter(vm, code); time = 59.9; vm.submit()
        #expect(vm.outcome == .win && vm.locked)
        time = 80; vm.tick()
        try await Task.sleep(for: .milliseconds(450))
        #expect(vm.outcome == .win && !vm.locked)
        #expect(vm.elapsed == 59.9)
    }

    @Test func timeoutCancelsWrongGuessAnimation() async throws {
        var time = 0.0
        let vm = GameViewModel(configuration: GameConfiguration.duo(code: code, hints: .direct, seconds: 60)!, now: { time })
        vm.resume(); enter(vm, [.white, .white, .white, .white]); time = 59.9; vm.submit()
        time = 60; vm.tick()
        try await Task.sleep(for: .milliseconds(450))
        #expect(vm.outcome == .timeout && !vm.locked)
        #expect(vm.rows.count == 1)
    }

    @Test func restartAndPauseCancelAnimationSafely() async throws {
        let vm = solo(); vm.resume()
        enter(vm, [.white, .white, .white, .white]); vm.submit()
        vm.restart()
        try await Task.sleep(for: .milliseconds(450))
        #expect(vm.rows.count == 1 && vm.canEdit && vm.outcome == nil)
        enter(vm, [.white, .white, .white, .white]); vm.submit(); vm.pause()
        #expect(vm.rows.last?.revealed == 4 && !vm.locked)
        vm.resume(); #expect(vm.canEdit)
    }

    @Test func diskReloadAndExactlyOnceResult() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.store")
        let store = try ProgressStore(url: url)
        var saved = snapshot(outcome: .win)
        store.save(saved); store.save(saved)
        #expect(store.state.stats.games == 1 && store.state.stats.wins == 1)
        saved.answerRevealed = true
        store.save(saved)
        store.updateSettings { $0.sound = false; $0.haptics = false; $0.allowAnswer = false }
        let reloaded = try ProgressStore(url: url)
        #expect(reloaded.state == store.state)
        #expect(reloaded.state.solo?.answerRevealed == true)
        #expect(reloaded.state.completed == [1])
        let vm = GameViewModel(configuration: .solo(LevelStore.level(id: 1)), snapshot: reloaded.state.solo)
        #expect(vm.rows.last?.revealed == 4)
        #expect(vm.current[1] == .blue && vm.selected == 1)
        #expect(vm.elapsed == 12 && vm.outcome == .win)
    }

    @Test func failedSaveRetainsPendingStateAndCanRetry() throws {
        let store = try ProgressStore(inMemory: true)
        store.saveOperation = { _ in throw CocoaError(.fileWriteOutOfSpace) }
        let saved = snapshot(outcome: .win)
        store.save(saved)
        #expect(store.errorMessage != nil)
        #expect(store.state.completed == [1])
        store.saveOperation = { try $0.save() }
        store.persist(); store.save(saved)
        #expect(store.errorMessage == nil)
        #expect(store.state.stats.games == 1)
        let context = ModelContext(store.container)
        let record = try #require(context.fetch(FetchDescriptor<ProgressRecord>()).first)
        let decoded = try JSONDecoder().decode(SavedProgress.self, from: record.payload)
        #expect(decoded == store.state)
    }

    @Test func replacementCancelAndConfirmation() throws {
        let store = try ProgressStore(inMemory: true)
        store.save(snapshot())
        let app = AppModel(store: store)
        app.requestLevel(2)
        #expect(app.replacementLevel == 2 && store.state.solo?.levelID == 1)
        app.replacementLevel = nil
        #expect(store.state.solo?.levelID == 1)
        app.requestLevel(2); app.confirmReplacement()
        #expect(store.state.solo?.levelID == 2)
        #expect(store.state.stats.games == 0)
    }

    @Test func tutorialReplayAndDuoDoNotPolluteSolo() throws {
        let store = try ProgressStore(inMemory: true)
        let saved = snapshot()
        store.save(saved)
        store.finishTutorial(firstRun: false)
        #expect(store.state.solo == saved && store.state.completed.isEmpty && store.state.stats.games == 0)
        store.finishTutorial(firstRun: true)
        #expect(store.state.completed == [1] && store.state.stats.games == 0)
        let session = DuoSession()
        session.code = code.map { $0 }; session.prepare(feedback: { _ in })
        let game = try #require(session.game)
        game.reduceMotion = true; game.resume(); enter(game, code); game.submit()
        #expect(session.scores == [0, 1])
        game.onChange?(); #expect(session.scores == [0, 1])
        session.swap(); #expect(session.setter == 1 && session.scores == [0, 1])
        #expect(store.state.solo == saved)
    }

    @Test func answerSettingAndCompletedRecordSurviveRetry() throws {
        let store = try ProgressStore(inMemory: true)
        let vm = solo(); vm.reduceMotion = true; vm.resume()
        for _ in 0..<6 { enter(vm, [.white, .white, .white, .white]); vm.submit() }
        vm.revealAnswer(allowed: false); #expect(!vm.answerRevealed)
        vm.revealAnswer(allowed: true); #expect(vm.answerRevealed)
        let won = snapshot(outcome: .win); store.save(won)
        store.save(try #require(vm.snapshot()))
        #expect(store.state.completed == [1] && store.state.stats.games == 2 && store.state.stats.streak == 0)
        vm.restart(); store.save(try #require(vm.snapshot()))
        #expect(store.state.stats.games == 2)
    }

    @Test func corruptVersionThrowsWithoutDeletingData() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("broken.store")
        let store = try ProgressStore(url: url)
        let context = ModelContext(store.container)
        var bad = SavedProgress(); bad.version = 999
        let data = try JSONEncoder().encode(bad)
        context.insert(ProgressRecord(payload: data)); try context.save()
        #expect(throws: StoreError.self) { _ = try ProgressStore(url: url) }
        #expect(try context.fetch(FetchDescriptor<ProgressRecord>()).first?.payload == data)
    }
    @Test func settingsGateAudioAndHapticsIndependently() {
        var preferences = PlayerSettings()
        var audio = 0
        var haptics = 0
        let service = FeedbackService(settings: { preferences }, sound: { _ in audio += 1 }, haptic: { _ in haptics += 1 })
        service.play(.place)
        #expect(audio == 1 && haptics == 1)
        preferences.sound = false
        service.play(.submit)
        #expect(audio == 1 && haptics == 2)
        preferences.haptics = false
        service.play(.heartbeat)
        service.play(.win)
        #expect(audio == 1 && haptics == 2)
        preferences.sound = true
        service.play(.lose)
        #expect(audio == 2 && haptics == 2)
    }

    @Test func modeBoundaryReturnsToCorrectSelection() throws {
        let store = try ProgressStore(inMemory: true)
        let app = AppModel(store: store)
        app.openLevel(100); app.nextLevel()
        #expect(app.path == [.soloLevels] && app.selectedBand == .easy)
        app.openLevel(600); app.nextLevel()
        #expect(app.path == [.soloLevels] && app.selectedBand == .advanced)
        app.openLevel(99); app.nextLevel()
        #expect(app.game?.configuration.levelID == 100)
    }

    @Test func soloShortcutStartsAndResumesWithoutBrowsingWrites() throws {
        let store = try ProgressStore(inMemory: true)
        let app = AppModel(store: store)
        app.showSoloLevels()
        #expect(app.path == [.soloLevels] && app.selectedBand == .easy)
        #expect(app.soloShortcut.title == "开始闯关 · 简单第 1 关")
        app.selectedBand = .advanced; app.expandedChapters = [3]
        #expect(store.state.solo == nil && app.advancedLevel == nil)
        app.performSoloShortcut()
        #expect(app.game?.configuration.levelID == 1 && app.selectedBand == .easy)
        #expect(app.path.count == 2)
        app.leaveGame()
        let saved = snapshot(id: 151)
        store.save(saved)
        app.showSoloLevels()
        #expect(app.selectedBand == .advanced && app.expandedChapters.contains(1))
        #expect(app.soloShortcut.title == "继续闯关 · 进阶第 51 关")
        app.selectedBand = .easy
        #expect(store.state.solo == saved && app.advancedLevel == nil)
        app.performSoloShortcut()
        #expect(app.advancedLevel == 151 && store.state.solo == saved)
        app.confirmAdvancedHelp()
        #expect(app.game?.roundID == saved.roundID && app.game?.current == saved.current)
        #expect(app.game?.elapsed == 12 && app.selectedBand == .advanced)
        app.expandedChapters.remove(0)
        app.leaveGame()
        #expect(app.path == [.soloLevels] && app.expandedChapters == [1])
    }

    @Test func soloShortcutNextAndModeEnds() throws {
        let store = try ProgressStore(inMemory: true)
        let app = AppModel(store: store)
        for id in [1, 99, 101, 599] {
            store.save(snapshot(id: id, outcome: .win))
            let stats = store.state.stats
            app.showSoloLevels(); app.performSoloShortcut()
            if app.advancedLevel != nil { app.confirmAdvancedHelp() }
            #expect(app.game?.configuration.levelID == id + 1 && app.game?.outcome == nil)
            #expect(store.state.stats == stats)
            app.leaveGame()
        }
        for id in [100, 600] {
            let saved = snapshot(id: id, outcome: .win)
            store.save(saved); app.showSoloLevels()
            #expect(app.soloShortcut.levelID == nil)
            #expect(app.soloShortcut.title == (id == 100 ? "简单模式已完成" : "进阶模式已完成"))
            app.performSoloShortcut()
            #expect(app.path == [.soloLevels] && store.state.solo == saved)
        }
    }

    @Test func soloShortcutRetryPreservesHistoryButGridRestoresResult() throws {
        let store = try ProgressStore(inMemory: true)
        let app = AppModel(store: store)
        store.save(snapshot(outcome: .win))
        var failed = snapshot(outcome: .lose)
        failed.answerRevealed = true
        store.save(failed)
        let stats = store.state.stats
        app.showSoloLevels(); app.requestLevel(1)
        #expect(app.game?.outcome == .lose && app.game?.answerRevealed == true)
        app.leaveGame(); app.selectedBand = .advanced
        #expect(app.soloShortcut.title == "重试 · 简单第 1 关")
        app.performSoloShortcut()
        let game = try #require(app.game)
        #expect(game.roundID != failed.roundID && game.outcome == nil)
        #expect(game.rows.count == 1 && game.current == [nil, nil, nil, nil])
        #expect(game.elapsed == 0 && !game.answerRevealed && game.selected == 0)
        #expect(app.selectedBand == .easy && store.state.completed == [1])
        game.onChange?()
        #expect(store.state.stats == stats && store.state.solo?.roundID == game.roundID)
    }

    @Test func soloBrowsingReplacementCancellationAndSessionReset() throws {
        let store = try ProgressStore(inMemory: true)
        let saved = snapshot()
        store.save(saved)
        let app = AppModel(store: store)
        app.showSoloLevels(); app.selectedBand = .advanced; app.expandedChapters = [5]
        app.requestLevel(351)
        #expect(app.replacementLevel == 351 && app.advancedLevel == nil)
        app.replacementLevel = nil
        #expect(store.state.solo == saved && app.selectedBand == .advanced && app.expandedChapters == [5])
        app.showSoloLevels()
        #expect(app.selectedBand == .easy && app.expandedChapters == [0])
        app.selectedBand = .advanced; app.requestLevel(351); app.confirmReplacement()
        #expect(app.advancedLevel == 351 && store.state.solo == saved)
        app.confirmAdvancedHelp(); app.selectLevels()
        #expect(app.path == [.soloLevels] && app.selectedBand == .advanced)
        #expect(app.expandedChapters.contains(5) && store.state.solo?.levelID == 351)
    }

    @Test func departingGameCannotOverwriteNewSoloSave() throws {
        let store = try ProgressStore(inMemory: true)
        let app = AppModel(store: store)
        app.openLevel(1)
        let old = try #require(app.game)
        app.openLevel(2)
        let newRound = app.game?.roundID
        old.pause(); old.onChange?()
        #expect(store.state.solo?.levelID == 2 && store.state.solo?.roundID == newRound)
        app.leaveGame()
        old.onChange?()
        #expect(store.state.solo?.levelID == 2)
    }

}
