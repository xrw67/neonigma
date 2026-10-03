import SwiftUI
import Core

/// 色珠(VDD §4.1):空槽 / 填充 / 选中 / 幽灵 四态。
/// 填充为柔和纯色,选中为深棕描边。
struct PegView: View {
    let color: PegColor?
    var size: CGFloat = Theme.pegSize
    var selected = false
    var ghost = false

    var body: some View {
        let corner = size * 6 / 44
        RoundedRectangle(cornerRadius: corner)
            .fill(color.map(Theme.pegBase) ?? Theme.well)
            .overlay(RoundedRectangle(cornerRadius: corner).strokeBorder(Theme.line.opacity(color == .white ? 1 : 0), lineWidth: 1))
            .frame(width: size, height: size)
            .overlay {
                if selected {
                    RoundedRectangle(cornerRadius: corner + 3)
                        .strokeBorder(Theme.selection, lineWidth: 2.5)
                        .padding(-3)
                }
            }
    }
}

/// 直接提示行(VDD §4.3):4 槽与棋盘四列对齐,逐格三态。
struct DirectHintDots: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                    .animation(reduceMotion ? nil : .spring(duration: 0.35).delay(Double(i) * 0.05), value: revealed)
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
            .overlay(Circle().strokeBorder(Theme.line, lineWidth: state == .wt ? 1 : 0))
            .frame(width: 9, height: 9)
    }
    private var fill: Color {
        switch state {
        case .on: Theme.hintOn
        case .wt: Theme.hintWt
        case .off: Theme.hintOff
        }
    }

}

/// 间接提示徽章(VDD §4.4,2026-10-01 定稿):固定 2×2 槽位、约 41×41,
/// 绿先白后按行主序点亮;点数不足的位置保持空(不渲染灭点)。
struct IndirectBadge: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                        .animation(reduceMotion ? nil : .spring(duration: 0.35).delay(Double(idx) * 0.05), value: revealed)
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

    }
}

/// LED 数字屏(VDD §4.8):等宽 + 琥珀纯色。
struct LEDView: View {
    let text: String
    var small = false
    var danger = false

    var body: some View {
        Text(text)
            .font(.system(size: small ? 12 : 15, weight: .bold, design: .monospaced))
            .kerning(1.5)
            .foregroundColor(danger ? Theme.hintWt : Theme.bg)
            .padding(.horizontal, small ? 10 : 14)
            .padding(.vertical, small ? 3 : 5)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(danger ? Theme.danger : Theme.status)
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.line, lineWidth: 1))
            )
    }
}

/// 主按钮(琥珀纯色)/ 次按钮(面板底)VDD §4.6。
struct PrimaryButtonStyle: ButtonStyle {
    var disabled = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(disabled ? Theme.text3 : Theme.text1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .frame(minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(disabled ? Theme.panel2 : Theme.amber)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.text2)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .frame(minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.panel)
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.line, lineWidth: 1))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
