import Foundation
import Core

// CI 门槛验证(PRD §7.3 / 技术选型 §2.10):
// ① PRD 示例用例;② 840×2401 全枚举等价性;③ 关卡表约束 + 全量可解性。
// 用法:swift run --package-path Core validate [--input <levels.json>]
// 退出码非 0 即失败。

var failed = false

@MainActor func check(_ name: String, _ body: () throws -> Bool) {
    do {
        let ok = try body()
        print(ok ? "✓ \(name)" : "✗ \(name)")
        if !ok { failed = true }
    } catch {
        print("✗ \(name) — 异常: \(error)")
        failed = true
    }
}

// ---------- ① PRD 示例 ----------
let code: [PegColor] = [.red, .green, .blue, .yellow]
check("① PRD A1–A3 示例判定") {
    let a1 = CodeBreakerEngine.evaluate(code: code, guess: [.green, .red, .blue, .white])
    let a2 = CodeBreakerEngine.evaluate(code: code, guess: [.blue, .blue, .white, .white])
    let a3 = CodeBreakerEngine.evaluate(code: code, guess: [.yellow, .blue, .green, .red])
    return a1.cells == [.wt, .wt, .on, .off]
        && a2.greens == 0 && a2.whites == 1
        && a3.greens == 0 && a3.whites == 4
}

// ---------- ② 全枚举等价性(840 × 7^4) ----------
check("② 全枚举等价性 840×2401(验收 A4)") {
    let colors = PegColor.allCases
    var guesses = [[PegColor]]()
    guesses.reserveCapacity(2_401)
    for a in colors { for b in colors { for c in colors { for d in colors {
        guesses.append([a, b, c, d])
    } } } }
    var mismatch = 0
    for code in CodeSpace.allCodes {
        for guess in guesses {
            let e = CodeBreakerEngine.evaluate(code: code, guess: guess)
            if e.cells.filter({ $0 == .on }).count != e.greens
                || e.cells.filter({ $0 == .wt }).count != e.whites
                || e.greens + e.whites > 4 {
                mismatch += 1
            }
        }
    }
    print("   共 \(CodeSpace.allCodes.count * guesses.count) 次判定,不一致 \(mismatch) 处")
    return mismatch == 0
}

// ---------- ③ 关卡表 ----------
let args = CommandLine.arguments
var input = "Neonigma/Resources/levels.json"
if let i = args.firstIndex(of: "--input"), i + 1 < args.count {
    input = args[i + 1]
}

let table: LevelTable
if FileManager.default.fileExists(atPath: input) {
    let data = try Data(contentsOf: URL(fileURLWithPath: input))
    table = try JSONDecoder().decode(LevelTable.self, from: data)
    print("· 关卡表来源:\(input)")
} else {
    table = LevelGenerator.table()
    print("· ⚠️ 未找到 \(input),改为内存生成验证")
}

check("③-a 表结构:600 关、编号 1...600 连续、easy/advanced 段位正确") {
    table.levels.count == 600
        && table.levels.map(\.id) == Array(1...600)
        && table.levels.allSatisfy { ($0.id <= 100) == ($0.band == .easy) }
}

check("③-b FR-L3 起始线索约束") {
    table.levels.allSatisfy { level in
        let e = CodeBreakerEngine.evaluate(code: level.code, guess: level.clue)
        switch level.id {
        case 1...20:    return e.greens >= 2
        case 21...100:  return (1...2).contains(e.greens)
        case 101...250: return e.greens == 1
        case 251...450: return e.greens == 0 && e.whites >= 2
        default:        return e.greens == 0 && e.whites <= 1
        }
    }
}

check("③-c 全量可解性:600 关均 ≤6 次玩家猜测(验收 A11)") {
    var histogram = [Int](repeating: 0, count: Solver.maxPlayerGuesses + 1)
    var unsolved = 0
    for level in table.levels {
        var rng = SplitMix64(seed: 0x9E37_79B9_7F4A_7C15 &+ UInt64(level.id))
        if let n = Solver.guessesToSolve(level: level, rng: &rng), n <= Solver.maxPlayerGuesses {
            histogram[n] += 1
        } else {
            unsolved += 1
            print("   ✗ 关卡 \(level.displayID)(id=\(level.id))6 次内未破译")
        }
    }
    let solved = 600 - unsolved
    let avg = Double((1...6).reduce(0) { $0 + $1 * histogram[$1] }) / Double(solved)
    print("   破译步数分布 \(Array(histogram.dropFirst())),平均 \(String(format: "%.2f", avg)) 步")
    return unsolved == 0
}

if failed {
    print("验证未通过")
    exit(1)
}
print("全部验证通过 ✅")
