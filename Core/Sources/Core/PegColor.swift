/// 七种密码色(PRD §3.1)。
/// rawValue 是关卡表 JSON 与 UI 调色盘的稳定序号,不得改动顺序。
public enum PegColor: Int, Codable, CaseIterable, Sendable, Hashable {
    case red = 0, orange, yellow, green, blue, purple, white
}
