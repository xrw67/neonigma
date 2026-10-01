import Testing
import Foundation
@testable import Core

@Suite struct LevelTableTests {

    @Test("整表:600 关、编号连续、段位正确")
    func tableShape() {
        let table = LevelGenerator.table()
        #expect(table.levels.count == LevelTable.count)
        #expect(table.version == 1)
        #expect(table.levels.map(\.id) == Array(1...600))
        for level in table.levels where level.id <= 100 {
            #expect(level.band == .easy)
        }
        for level in table.levels where level.id > 100 {
            #expect(level.band == .advanced)
        }
    }

    @Test("密码与线索均为 4 色不重复")
    func codesWellFormed() {
        for level in LevelGenerator.table().levels {
            #expect(level.code.count == 4 && Set(level.code).count == 4)
            #expect(level.clue.count == 4 && Set(level.clue).count == 4)
        }
    }

    @Test("FR-L3 起始线索约束按段满足")
    func difficultyCurve() {
        for level in LevelGenerator.table().levels {
            let e = CodeBreakerEngine.evaluate(code: level.code, guess: level.clue)
            switch level.id {
            case 1...20:    #expect(e.greens >= 2)
            case 21...100:  #expect((1...2).contains(e.greens))
            case 101...250: #expect(e.greens == 1)
            case 251...450: #expect(e.greens == 0 && e.whites >= 2)
            default:        #expect(e.greens == 0 && e.whites <= 1)
            }
        }
    }

    @Test("确定性:同 id 重复生成结果一致(任意设备同一关卡)")
    func deterministicGeneration() {
        for id in [1, 2, 20, 21, 100, 101, 137, 250, 251, 450, 451, 599, 600] {
            #expect(LevelGenerator.level(id: id) == LevelGenerator.level(id: id))
        }
    }

    @Test("展示编号格式")
    func displayIDs() {
        #expect(LevelGenerator.level(id: 1).displayID == "E-001")
        #expect(LevelGenerator.level(id: 23).displayID == "E-023")
        #expect(LevelGenerator.level(id: 101).displayID == "A-001")
        #expect(LevelGenerator.level(id: 600).displayID == "A-500")
    }

    @Test("可解性抽样:每 17 关取 1,均在 ≤6 次玩家猜测内破译(验收 A11 抽样;全量见 Validate)")
    func solvableSample() {
        for id in stride(from: 1, through: 600, by: 17) {
            let level = LevelGenerator.level(id: id)
            var rng = SplitMix64(seed: 0xDEAD_BEEF &+ UInt64(id))
            let n = Solver.guessesToSolve(level: level, rng: &rng)
            #expect(n != nil && n! <= 6, "关卡 \(id) 6 次内不可解")
        }
    }

    @Test("JSON 往返一致(Codable)")
    func codableRoundTrip() throws {
        let table = LevelGenerator.table()
        let data = try JSONEncoder().encode(table)
        let decoded = try JSONDecoder().decode(LevelTable.self, from: data)
        #expect(decoded == table)
    }
}
