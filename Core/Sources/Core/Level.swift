import Foundation

/// 难度段(PRD FR-L3)。
public enum Band: String, Codable, Sendable, CaseIterable {
    case easy       // E001–E100,直接提示
    case advanced   // A001–A500,间接提示
}

/// 单关:密码 + 起始线索(第 1 行,PRD FR-S1)。
public struct Level: Codable, Equatable, Hashable, Sendable {
    public let id: Int              // 全局编号 1...600,seed 由它派生
    public let band: Band
    public let code: [PegColor]
    public let clue: [PegColor]

    public init(id: Int, band: Band, code: [PegColor], clue: [PegColor]) {
        self.id = id
        self.band = band
        self.code = code
        self.clue = clue
    }

    /// 展示编号:E-023 / A-137(对应原型数字屏)。
    public var displayID: String {
        band == .easy
            ? String(format: "E-%03d", id)
            : String(format: "A-%03d", id - 100)
    }
}

/// 600 关查找表(随包内置,PRD §3.6)。
public struct LevelTable: Codable, Equatable, Sendable {
    public let version: Int
    public let levels: [Level]

    public init(version: Int, levels: [Level]) {
        self.version = version
        self.levels = levels
    }

    public static let count = 600
}
