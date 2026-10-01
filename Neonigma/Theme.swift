import SwiftUI
import Core

/// 设计 token(与 docs/视觉设计文档.md §3 / design/css/tokens.css 一一对应)。
enum Theme {
    static func color(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255.0,
              green: Double((hex >> 8) & 0xFF) / 255.0,
              blue: Double(hex & 0xFF) / 255.0)
    }

    // MARK: 背景层级(§3.3)
    static let bg = color(0x0E1116)
    static let panel = color(0x161B22)
    static let panel2 = color(0x1D232C)
    static let well = color(0x151B26)
    static let line = color(0x262E3A)

    // MARK: 文字层级(§3.4)
    static let text1 = color(0xF0F3F7)
    static let text2 = color(0x9BA6B5)
    static let text3 = color(0x5C6675)

    // MARK: 提示三态(§3.2)
    static let hintOn = color(0x30D158)
    static let hintWt = color(0xF2F0EF)
    static let hintOff = color(0x262E3A)

    // MARK: 功能色(§3.5)
    static let amber = color(0xFFB224)
    static let danger = color(0xFF5D5D)
    static let star = color(0xFFC53D)

    // MARK: 密码七色 base(§3.1;glow = base 半透明)
    static func pegBase(_ c: PegColor) -> Color {
        switch c {
        case .red:    color(0xE5484D)
        case .orange: color(0xF76B15)
        case .yellow: color(0xFFC53D)
        case .green:  color(0x46A758)
        case .blue:   color(0x0091FF)
        case .purple: color(0x8E4EC6)
        case .white:  color(0xF2F0EF)
        }
    }

    static let pegSize: CGFloat = 44
}
