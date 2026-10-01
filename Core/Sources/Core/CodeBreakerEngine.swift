/// 提示点三态(PRD §3.2/§3.3)。直接提示 = cells 逐格展开;间接提示 = greens/whites 聚合计数。
/// 两者出自同一次 evaluate,天然严格等价(PRD §3.4,验收 A4)。
public enum CellHint: UInt8, Codable, Sendable, Hashable {
    case off = 0   // 颜色不存在
    case on = 1    // 对色对位(绿)
    case wt = 2    // 对色错位(白)
}

/// 一次猜测的判定结果。
public struct Evaluation: Equatable, Sendable {
    public let greens: Int
    public let whites: Int
    public let cells: [CellHint]

    public init(greens: Int, whites: Int, cells: [CellHint]) {
        self.greens = greens
        self.whites = whites
        self.cells = cells
    }
}

/// 规则引擎(纯函数,PRD §3.4):
/// 第一遍记对位(绿)并消费;第二遍从左到右为剩余格配错位(白)并消费;其余为灭。
/// 与 design/js/demo.js 的 evaluate 逐行为一致,二者互为对照实现。
public enum CodeBreakerEngine {

    public static func evaluate(code: [PegColor], guess: [PegColor]) -> Evaluation {
        precondition(code.count == guess.count, "code/guess 长度不一致")
        precondition(!code.isEmpty, "密码不能为空")
        let n = code.count
        var used = [Bool](repeating: false, count: n)
        var cells = [CellHint](repeating: .off, count: n)
        var greens = 0
        var whites = 0
        for i in 0..<n where guess[i] == code[i] {
            cells[i] = .on
            used[i] = true
            greens += 1
        }
        for i in 0..<n where cells[i] == .off {
            for j in 0..<n where !used[j] && guess[i] == code[j] {
                cells[i] = .wt
                used[j] = true
                whites += 1
                break
            }
        }
        return Evaluation(greens: greens, whites: whites, cells: cells)
    }
}

/// 密码空间:7 色取 4 不重复的有序排列,共 840 种(PRD §2.2)。
public enum CodeSpace {
    public static let codeLength = 4
    public static let allCodes: [[PegColor]] = permutations(of: PegColor.allCases, taking: codeLength)

    static func permutations<T>(of items: [T], taking k: Int) -> [[T]] {
        guard k > 0, k <= items.count else { return [] }
        var result: [[T]] = []
        var current: [T] = []
        var used = [Bool](repeating: false, count: items.count)
        func recurse() {
            if current.count == k {
                result.append(current)
                return
            }
            for i in items.indices where !used[i] {
                used[i] = true
                current.append(items[i])
                recurse()
                current.removeLast()
                used[i] = false
            }
        }
        recurse()
        return result
    }
}
