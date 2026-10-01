import Foundation
import Core

// 生成 600 关查找表并写为 JSON(随包内置)。
// 用法:swift run --package-path Core gen-levels [--output <path>]

let args = CommandLine.arguments
var output = "Neonigma/Resources/levels.json"
if let i = args.firstIndex(of: "--output"), i + 1 < args.count {
    output = args[i + 1]
}

let table = LevelGenerator.table()
let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]   // 稳定字节输出,CI 可 diff
let data = try encoder.encode(table)

let outputURL = URL(fileURLWithPath: output)
try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try data.write(to: outputURL)

// 摘要
let easy = table.levels.filter { $0.band == .easy }.count
print("✓ 已生成 \(table.levels.count) 关(简单 \(easy) / 进阶 \(table.levels.count - easy))→ \(output)(\(data.count) 字节)")
