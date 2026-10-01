/// 关卡生成(PRD §3.6 / FR-L3 难度曲线)。
/// 完全确定性:seed = 全局编号 × 质数 + 重试偏移;起始线索按段内约束筛选;
/// 生成后立即用启发式求解器验证 6 次内可解,不可解则换种子重试(FR-L5)。
public enum LevelGenerator {

    struct ClueConstraint {
        var greens: ClosedRange<Int>
        var whites: ClosedRange<Int>
    }

    /// FR-L3 起始线索信息量递减:
    /// E001–020 ≥2 绿(教学);E021–100 1–2 绿;A001–150 恰 1 绿;
    /// A151–350 0 绿白≥2;A351–500 0 绿白≤1(高难低信息开局)。
    static func constraint(for id: Int) -> ClueConstraint {
        switch id {
        case 1...20:    return ClueConstraint(greens: 2...4, whites: 0...4)
        case 21...100:  return ClueConstraint(greens: 1...2, whites: 0...4)
        case 101...250: return ClueConstraint(greens: 1...1, whites: 0...3)
        case 251...450: return ClueConstraint(greens: 0...0, whites: 2...4)
        default:        return ClueConstraint(greens: 0...0, whites: 0...1)
        }
    }

    /// 生成单关(确定性:同 id 永远得到同一关)。
    public static func level(id: Int) -> Level {
        precondition((1...LevelTable.count).contains(id), "关卡编号越界: \(id)")
        let band: Band = id <= 100 ? .easy : .advanced
        for attempt in 0..<64 {
            var rng = SplitMix64(seed: UInt64(id) &* 1_000_003 &+ UInt64(attempt))
            let candidate = draw(id: id, band: band, using: &rng)
            var solverRNG = SplitMix64(seed: 0x9E37_79B9_7F4A_7C15 &+ UInt64(id) &+ UInt64(attempt))
            if let n = Solver.guessesToSolve(level: candidate, rng: &solverRNG), n <= 6 {
                return candidate
            }
        }
        fatalError("关卡 \(id):64 次重试均未得到 6 步内可解的关卡(理论不应发生,请检查约束)")
    }

    /// 抽一关:密码一次抽取,线索按约束重抽(至多 10000 次,各段约束均可满足)。
    static func draw(id: Int, band: Band, using rng: inout SplitMix64) -> Level {
        let constraint = constraint(for: id)
        let code = rng.sampleDistinct(PegColor.allCases, count: CodeSpace.codeLength)
        for _ in 0..<10_000 {
            let clue = rng.sampleDistinct(PegColor.allCases, count: CodeSpace.codeLength)
            let evaluation = CodeBreakerEngine.evaluate(code: code, guess: clue)
            if constraint.greens.contains(evaluation.greens),
               constraint.whites.contains(evaluation.whites) {
                return Level(id: id, band: band, code: code, clue: clue)
            }
        }
        fatalError("关卡 \(id):约束采样 10000 次未命中(不应发生)")
    }

    /// 生成整表(1...600)。
    public static func table() -> LevelTable {
        LevelTable(version: 1, levels: (1...LevelTable.count).map(level(id:)))
    }
}
