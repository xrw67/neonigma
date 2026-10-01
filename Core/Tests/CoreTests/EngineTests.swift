import Testing
import Foundation
@testable import Core

// PRD §3.4 / §11 示例的固定密码:红 绿 蓝 黄
private let code: [PegColor] = [.red, .green, .blue, .yellow]

private func ev(_ guess: [PegColor]) -> Evaluation {
    CodeBreakerEngine.evaluate(code: code, guess: guess)
}

@Suite struct EngineTests {

    @Test("A1 猜绿红蓝白 → ⚪⚪🟢⚫(1 绿 2 白)")
    func a1() {
        let e = ev([.green, .red, .blue, .white])
        #expect(e.cells == [.wt, .wt, .on, .off])
        #expect(e.greens == 1 && e.whites == 2)
    }

    @Test("A2 猜蓝蓝白白(重复猜色)→ 0 绿 1 白,重复只计一次")
    func a2() {
        let e = ev([.blue, .blue, .white, .white])
        #expect(e.cells == [.wt, .off, .off, .off])
        #expect(e.greens == 0 && e.whites == 1)
    }

    @Test("A3 猜黄蓝绿红 → 0 绿 4 白")
    func a3() {
        let e = ev([.yellow, .blue, .green, .red])
        #expect(e.cells == [.wt, .wt, .wt, .wt])
        #expect(e.greens == 0 && e.whites == 4)
    }

    @Test("全对 → 4 绿即破译")
    func allGreen() {
        let e = ev(code)
        #expect(e.greens == 4 && e.whites == 0)
        #expect(e.cells == [.on, .on, .on, .on])
    }

    @Test("全不存在 → 4 灭")
    func allOff() {
        let e = ev([.orange, .white, .purple, .orange])
        #expect(e.greens == 0 && e.whites == 0)
        #expect(e.cells.allSatisfy { $0 == .off })
    }
}

@Suite struct CodeSpaceTests {

    @Test("7 色取 4 不重复 = 840 种,且互不相同")
    func count840() {
        #expect(CodeSpace.allCodes.count == 840)
        #expect(Set(CodeSpace.allCodes).count == 840)
    }

    @Test("每个密码 4 色互不相同")
    func distinctColors() {
        for c in CodeSpace.allCodes {
            #expect(Set(c).count == 4)
        }
    }
}

@Suite struct ExhaustiveEquivalenceTests {

    /// 验收 A4:全枚举 840 密码 × 7^4 全部猜测(含重复猜色,共 2,016,840 次),
    /// 断言逐格展开与聚合计数严格等价,且总提示数 ≤ 4。
    @Test("直接提示逐格聚合 == 间接提示计数(全枚举)")
    func equivalence() {
        let colors = PegColor.allCases
        var guesses: [[PegColor]] = []
        guesses.reserveCapacity(2_401)
        for a in colors { for b in colors { for c in colors { for d in colors {
            guesses.append([a, b, c, d])
        } } } }

        var mismatches = 0
        var overflow = 0
        for code in CodeSpace.allCodes {
            for guess in guesses {
                let e = CodeBreakerEngine.evaluate(code: code, guess: guess)
                let greens = e.cells.filter { $0 == .on }.count
                let whites = e.cells.filter { $0 == .wt }.count
                if greens != e.greens || whites != e.whites { mismatches += 1 }
                if e.greens + e.whites > 4 { overflow += 1 }
            }
        }
        #expect(mismatches == 0)
        #expect(overflow == 0)
    }
}

@Suite struct SplitMix64Tests {

    @Test("确定性:同 seed 同序列")
    func deterministic() {
        var a = SplitMix64(seed: 42)
        var b = SplitMix64(seed: 42)
        let seqA = (0..<100).map { _ in a.next() }
        let seqB = (0..<100).map { _ in b.next() }
        #expect(seqA == seqB)
    }

    @Test("不同 seed 序列不同")
    func diverges() {
        var a = SplitMix64(seed: 1)
        var b = SplitMix64(seed: 2)
        let seqA = (0..<100).map { _ in a.next() }
        let seqB = (0..<100).map { _ in b.next() }
        #expect(seqA != seqB)
    }

    @Test("sampleDistinct:数量正确且无重复")
    func sample() {
        var rng = SplitMix64(seed: 7)
        for _ in 0..<200 {
            let s = rng.sampleDistinct(PegColor.allCases, count: 4)
            #expect(s.count == 4)
            #expect(Set(s).count == 4)
        }
    }
}
