/// 带种子 PRNG(PRD §3.6):关卡生成禁用系统随机,seed = 关卡全局编号,
/// 保证任何设备上同一关卡密码一致(每日挑战与异步对战的前置条件)。
public struct SplitMix64: RandomNumberGenerator, Sendable {
    public private(set) var state: UInt64

    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// 均匀取 [0, bound)。
    public mutating func next(_ bound: Int) -> Int {
        precondition(bound > 0)
        return Int(next() % UInt64(bound))
    }

    /// 无重复抽取 count 个(部分 Fisher–Yates)。
    public mutating func sampleDistinct<T>(_ items: [T], count: Int) -> [T] {
        let k = min(count, items.count)
        var pool = items
        var out: [T] = []
        out.reserveCapacity(k)
        for _ in 0..<k {
            let idx = next(pool.count)
            out.append(pool[idx])
            pool.swapAt(idx, pool.count - 1)
            pool.removeLast()
        }
        return out
    }
}
