/// 可解性验证求解器(FR-L5 / 验收 A11)。
/// 策略:维持与全部已有提示一致的候选集,每步从中随机猜一个(经典"一致性猜测",
/// 4 色不重复 7 色库下平均 ~4.2 步)。返回破译所用猜测数(不含起始线索行);
/// 6 次用尽仍未破译返回 nil。关卡生成与 Validate 均以它为门槛。
public enum Solver {

    public static let maxPlayerGuesses = 6   // 7 行 − 1 条起始线索行(PRD §2.2)

    public static func guessesToSolve(level: Level, rng: inout SplitMix64) -> Int? {
        var candidates = CodeSpace.allCodes
        let clueEvaluation = CodeBreakerEngine.evaluate(code: level.code, guess: level.clue)
        candidates = candidates.filter {
            CodeBreakerEngine.evaluate(code: $0, guess: level.clue) == clueEvaluation
        }
        for guessNumber in 1...maxPlayerGuesses {
            guard !candidates.isEmpty, let guess = candidates.randomElement(using: &rng) else {
                return nil
            }
            let evaluation = CodeBreakerEngine.evaluate(code: level.code, guess: guess)
            if evaluation.greens == CodeSpace.codeLength {
                return guessNumber
            }
            candidates = candidates.filter {
                CodeBreakerEngine.evaluate(code: $0, guess: guess) == evaluation
            }
        }
        return nil
    }
}
