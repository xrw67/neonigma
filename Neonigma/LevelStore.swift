import Foundation
import Core

/// 关卡表加载(随包内置,由 `swift run --package-path Core GenLevels` 生成)。
enum LevelStore {
    static let table: LevelTable = load()

    private static func load() -> LevelTable {
        guard let url = Bundle.main.url(forResource: "levels", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let table = try? JSONDecoder().decode(LevelTable.self, from: data) else {
            fatalError("levels.json 缺失或损坏:先运行 swift run --package-path Core GenLevels")
        }
        return table
    }

    static func level(id: Int) -> Level {
        table.levels[id - 1]
    }
}
