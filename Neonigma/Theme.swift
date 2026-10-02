import SwiftUI
import Core

/// 设计 token(以 docs/视觉设计文档.md 的暖色纸面规范为准)。
enum Theme {
    static func color(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255.0,
              green: Double((hex >> 8) & 0xFF) / 255.0,
              blue: Double(hex & 0xFF) / 255.0)
    }

    // MARK: 背景层级(§3.3)
    static let bg = color(0xFAF8EF)
    static let panel = color(0xEEE6DA)
    static let panel2 = color(0xE5DACA)
    static let well = color(0xBCAF9F)
    static let line = color(0xC9BDAD)

    // MARK: 文字层级(§3.4)
    static let text1 = color(0x403D35)
    static let text2 = color(0x766E64)
    static let text3 = color(0x847B70)

    // MARK: 提示三态(§3.2)
    static let hintOn = color(0x39764A)
    static let hintWt = color(0xFFFDF7)
    static let hintOff = color(0x776B5D)

    // MARK: 功能色(§3.5)
    static let amber = color(0xE85D3F)
    static let danger = color(0xB83F2D)
    static let star = color(0x967016)

    // MARK: 密码七色 纯色
    static func pegBase(_ c: PegColor) -> Color {
        switch c {
        case .red:    color(0xE97868)
        case .orange: color(0xF2AA74)
        case .yellow: color(0xEDCD62)
        case .green:  color(0x76A982)
        case .blue:   color(0x6A9EC8)
        case .purple: color(0xAB89BC)
        case .white:  color(0xF5F0E8)
        }
    }

    static let board = color(0xA49380)
    static let selection = color(0x57483B)
    static let status = color(0x403D35)

    static let pegSize: CGFloat = 44
}
