import Foundation
import SwiftData
import Observation
import Core

struct PlayerSettings: Codable, Equatable {
    var sound = true
    var haptics = true
    var allowAnswer = true
    var tutorialSeen = false
    var advancedHelpSeen = false
}

struct PlayerStats: Codable, Equatable {
    var games = 0
    var wins = 0
    var winningGuesses = 0
    var streak = 0
    var bestStreak = 0
}

/// 保存输入而非提示,加载后通过规则引擎重建完整反馈。
struct SoloSnapshot: Codable, Equatable {
    var version = 1
    var levelID: Int
    var roundID: UUID
    var guesses: [[PegColor]]
    var current: [PegColor?]
    var selected: Int
    var elapsed: TimeInterval
    var outcome: GameOutcome?
    var answerRevealed: Bool

    func validate() throws {
        guard version == 1, (1...600).contains(levelID), guesses.count <= 6,
              guesses.allSatisfy({ $0.count == 4 }), current.count == 4,
              (0..<4).contains(selected), elapsed.isFinite, elapsed >= 0 else {
            throw StoreError.invalidSnapshot
        }
    }
}

struct SavedProgress: Codable, Equatable {
    var version = 1
    var settings = PlayerSettings()
    var stats = PlayerStats()
    var completed: Set<Int> = []
    var countedRounds: Set<UUID> = []
    var solo: SoloSnapshot?
}

/// 一个事务提交存档、完成记录与统计,避免进程退出时只写入其中一部分。
@Model final class ProgressRecord {
    @Attribute(.unique) var key: String
    var payload: Data
    init(payload: Data) { key = "player"; self.payload = payload }
}

enum StoreError: LocalizedError {
    case invalidSnapshot
    var errorDescription: String? { "存档版本或内容无法读取,原数据已保留。" }
}

@MainActor @Observable final class ProgressStore {
    private(set) var state: SavedProgress
    var errorMessage: String?
    let container: ModelContainer
    private let context: ModelContext
    /// 测试可注入失败;生产环境直接提交 SwiftData 事务。
    @ObservationIgnored var saveOperation: (ModelContext) throws -> Void = { try $0.save() }

    init(url: URL? = nil, inMemory: Bool = false) throws {
        let schema = Schema([ProgressRecord.self])
        let configuration: ModelConfiguration
        if let url {
            configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
        }
        container = try ModelContainer(for: schema, configurations: [configuration])
        context = ModelContext(container)
        context.autosaveEnabled = false
        if let record = try context.fetch(FetchDescriptor<ProgressRecord>()).first {
            state = try JSONDecoder().decode(SavedProgress.self, from: record.payload)
            guard state.version == 1 else { throw StoreError.invalidSnapshot }
            try state.solo?.validate()
        } else {
            state = SavedProgress()
        }
    }

    func updateSettings(_ update: (inout PlayerSettings) -> Void) {
        update(&state.settings)
        persist()
    }

    func save(_ snapshot: SoloSnapshot) {
        state.solo = snapshot
        if let outcome = snapshot.outcome, state.countedRounds.insert(snapshot.roundID).inserted {
            state.stats.games += 1
            if outcome == .win {
                state.completed.insert(snapshot.levelID)
                state.stats.wins += 1
                state.stats.winningGuesses += snapshot.guesses.count
                state.stats.streak += 1
                state.stats.bestStreak = max(state.stats.bestStreak, state.stats.streak)
            } else {
                state.stats.streak = 0
            }
        }
        persist()
    }

    func finishTutorial(firstRun: Bool) {
        state.settings.tutorialSeen = true
        if firstRun { state.completed.insert(1) }
        persist()
    }

    func persist() {
        do {
            let payload = try JSONEncoder().encode(state)
            if let record = try context.fetch(FetchDescriptor<ProgressRecord>()).first {
                record.payload = payload
            } else {
                context.insert(ProgressRecord(payload: payload))
            }
            try saveOperation(context)
            errorMessage = nil
        } catch {
            context.rollback()
            errorMessage = "进度尚未保存: \(error.localizedDescription)"
        }
    }
}
