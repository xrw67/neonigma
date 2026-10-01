import SwiftUI
import Core

/// 色珠(VDD §4.1):空槽 / 填充 / 选中 / 幽灵 四态。
/// 填充 = base 底 + 顶部釉面高光 + 底部压暗 + 辉光;选中 = 琥珀描边 + 呼吸。
struct PegView: View {
    let color: PegColor?
    var size: CGFloat = Theme.pegSize
    var selected = false
    var ghost = false

    var body: some View {
        let corner = size * 12 / 44
        ZStack {
            if let color {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Theme.pegBase(color))
                    .overlay(
                        LinearGradient(colors: [.white.opacity(0.32), .clear],
                                       startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.52))
                            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                    )
                    .overlay(alignment: .bottom) {
                        LinearGradient(colors: [.clear, .black.opacity(0.3)],
                                       startPoint: .top, endPoint: .bottom)
                            .frame(height: size * 0.45)
                            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                    }
                    .shadow(color: Theme.pegBase(color).opacity(0.45), radius: size * 0.36)
            } else {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Theme.well)
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .strokeBorder(.white.opacity(0.07), lineWidth: 1.5)
                    )
            }
        }
        .frame(width: size, height: size)
        .opacity(ghost ? 0.5 : 1)
        .overlay {
            if selected {
                RoundedRectangle(cornerRadius: corner + 3, style: .continuous)
                    .strokeBorder(Theme.amber, lineWidth: 2.5)
                    .padding(-3)
            }
        }
    }
}

/// 直接提示行(VDD §4.3):4 槽与棋盘四列对齐,逐格三态。
struct DirectHintDots: View {
    let evaluation: Evaluation
    var revealed: Int = 4

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { i in
                Color.clear
                    .frame(width: Theme.pegSize, height: 9)
                    .overlay {
                        if i < revealed {
                            HintDot(state: evaluation.cells[i])
                                .transition(.scale(scale: 0.3).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(duration: 0.35).delay(Double(i) * 0.05), value: revealed)
            }
        }
    }
}

/// 提示点三态(9pt)。
struct HintDot: View {
    let state: CellHint
    var body: some View {
        Circle()
            .fill(fill)
            .frame(width: 9, height: 9)
            .shadow(color: glow, radius: 4)
    }
    private var fill: Color {
        switch state {
        case .on: Theme.hintOn
        case .wt: Theme.hintWt
        case .off: Theme.hintOff
        }
    }
    private var glow: Color {
        switch state {
        case .on: Theme.hintOn.opacity(0.55)
        case .wt: Theme.hintWt.opacity(0.5)
        case .off: .clear
        }
    }
}

/// 间接提示徽章(VDD §4.4,2026-10-01 定稿):固定 2×2 槽位、约 41×41,
/// 绿先白后按行主序点亮;点数不足的位置保持空(不渲染灭点)。
struct IndirectBadge: View {
    let evaluation: Evaluation
    var revealed: Int = 4
    /// 当前编辑行的低透明度占位(4 个灭点)。
    var placeholder = false

    var body: some View {
        let dots: [CellHint?] = {
            var d: [CellHint?] = []
            for _ in 0..<evaluation.greens { d.append(CellHint.on) }
            for _ in 0..<evaluation.whites { d.append(CellHint.wt) }
            while d.count < 4 { d.append(nil) }
            return d
        }()
        VStack(spacing: 5) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<2, id: \.self) { col in
                        let idx = row * 2 + col
                        ZStack {
                            if placeholder {
                                Circle().fill(Theme.hintOff).frame(width: 9, height: 9)
                            } else if idx < revealed, let s = dots[idx] {
                                HintDot(state: s)
                                    .transition(.scale(scale: 0.3).combined(with: .opacity))
                            }
                        }
                        .frame(width: 9, height: 9)
                        .animation(.spring(duration: 0.35).delay(Double(idx) * 0.05), value: revealed)
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.panel2)
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.line, lineWidth: 1))
        )
        .opacity(placeholder ? 0.5 : 1)
    }
}

/// LED 数字屏(VDD §4.8):等宽 + 琥珀 + 辉光。
struct LEDView: View {
    let text: String
    var small = false
    var danger = false

    var body: some View {
        Text(text)
            .font(.system(size: small ? 12 : 15, weight: .bold, design: .monospaced))
            .kerning(1.5)
            .foregroundColor(danger ? Theme.danger : Theme.amber)
            .padding(.horizontal, small ? 10 : 14)
            .padding(.vertical, small ? 3 : 5)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.color(0x0A0D12))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.line, lineWidth: 1))
            )
            .shadow(color: (danger ? Theme.danger : Theme.amber).opacity(0.35), radius: 8)
    }
}

/// 主按钮(琥珀渐变)/ 次按钮(面板底)VDD §4.6。
struct PrimaryButtonStyle: ButtonStyle {
    var disabled = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .foregroundStyle(disabled ? Theme.text3 : Theme.color(0x1A1204))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.color(0xFFD37A), Theme.amber, Theme.color(0xB26E00)],
                                         startPoint: .top, endPoint: .bottom))
                    .opacity(disabled ? 0.25 : 1)
            )
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(disabled ? 0 : 0.35), lineWidth: 1))
            .shadow(color: Theme.amber.opacity(disabled ? 0 : 0.3), radius: 10, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .foregroundStyle(Theme.text2)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.panel)
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.line, lineWidth: 1))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// 星级(FR-S4:≤2 次 3 星 / ≤4 次 2 星 / 其余 1 星)。
struct StarsView: View {
    let count: Int
    var big = false

    var body: some View {
        HStack(spacing: big ? 8 : 2) {
            ForEach(0..<3, id: \.self) { i in
                Text("★")
                    .font(.system(size: big ? 34 : 13, weight: .black))
                    .foregroundStyle(i < count ? Theme.star : Theme.hintOff)
                    .shadow(color: i < count ? Theme.star.opacity(0.5) : .clear, radius: big ? 10 : 4)
            }
        }
    }
}
