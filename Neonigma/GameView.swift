import SwiftUI
import Core

/// 对局页(VDD §6 基准栅格):
/// navbar → chipline → 图例 → 棋盘(底部对齐)→ 调色盘 → 按钮行。
struct GameView: View {
    @State private var vm: GameViewModel
    @State private var sheetPresented = false
    @Environment(\.dismiss) private var dismiss

    init(level: Level) {
        _vm = State(initialValue: GameViewModel(level: level))
    }

    var body: some View {
        VStack(spacing: 0) {
            navbar
            chipline
            if !vm.isEasy { legend }
            board
            controls
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .sensoryFeedback(.impact(weight: .medium), trigger: vm.rows.count)
        .sensoryFeedback(.success, trigger: isWin)
        .sensoryFeedback(.error, trigger: isLose)
        .onChange(of: vm.outcome) { _, newValue in
            if newValue != nil { sheetPresented = true }
        }
        .sheet(isPresented: $sheetPresented) { sheet }
    }

    private var isWin: Bool { if case .win = vm.outcome { true } else { false } }
    private var isLose: Bool { vm.outcome == .lose }

    // MARK: 区块

    private var navbar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.text2)
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.panel)
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.line, lineWidth: 1)))
            }
            Spacer()
            LEDView(text: vm.level.displayID)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.amber)
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.panel)
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.line, lineWidth: 1)))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 46)
    }

    private var chipline: some View {
        HStack {
            Text(vm.isEasy ? "简单 · 直接提示" : "进阶 · 间接提示")
            Spacer()
            Text("已用 \(vm.guessesUsed)/\(vm.maxGuesses) 次")
        }
        .font(.system(size: 12))
        .foregroundStyle(Theme.text2)
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
    }

    private var legend: some View {
        HStack(spacing: 14) {
            Label("对位个数", systemImage: "circle.fill").labelStyle(HintLegendStyle(color: Theme.hintOn))
            Label("错位个数", systemImage: "circle.fill").labelStyle(HintLegendStyle(color: Theme.hintWt))
            Spacer()
            Text("只报数量 · 不报位置").foregroundStyle(Theme.text3)
        }
        .font(.system(size: 11))
        .foregroundStyle(Theme.text3)
        .padding(.horizontal, 18)
        .padding(.bottom, 6)
    }

    private struct HintLegendStyle: LabelStyle {
        let color: Color
        func makeBody(configuration: Configuration) -> some View {
            HStack(spacing: 5) {
                Circle().fill(color).frame(width: 8, height: 8)
                    .shadow(color: color.opacity(0.5), radius: 3)
                configuration.title
            }
        }
    }

    // MARK: 棋盘

    private var board: some View {
        VStack(spacing: 9) {
            ForEach(vm.rows.indices, id: \.self) { i in
                submittedRow(vm.rows[i], index: i)
            }
            if vm.outcome == nil {
                currentRow
                ForEach(0..<ghostCount, id: \.self) { _ in ghostRow }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    private var ghostCount: Int {
        max(0, vm.maxGuesses + 1 - vm.rows.count - 1)
    }

    private var ghostRow: some View {
        HStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { _ in
                PegView(color: nil, ghost: true)
            }
        }
        .opacity(0.5)
    }

    private func submittedRow(_ row: GameViewModel.RowState, index: Int) -> some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                if index == 0 {
                    Text("第 1 行 · 起始线索")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.color(0x6BC1FF))
                }
                HStack(spacing: 10) {
                    ForEach(row.guess.indices, id: \.self) { i in
                        PegView(color: row.guess[i])
                    }
                }
                if vm.isEasy {
                    DirectHintDots(evaluation: row.evaluation, revealed: row.revealed)
                }
            }
            Spacer(minLength: 0)
            if !vm.isEasy {
                IndirectBadge(evaluation: row.evaluation, revealed: row.revealed)
            }
        }
        .padding(index == 0 ? 8 : 0)
        .background {
            if index == 0 {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.color(0x0091FF).opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.color(0x0091FF).opacity(0.18), lineWidth: 1))
            }
        }
    }

    private var currentRow: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text("第 \(vm.rows.count + 1) 行 · 编辑中")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.amber)
                HStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { i in
                        PegView(color: vm.current[i], selected: vm.selected == i)
                            .onTapGesture { vm.select(i) }
                    }
                }
            }
            Spacer(minLength: 0)
            if !vm.isEasy {
                IndirectBadge(evaluation: Evaluation(greens: 0, whites: 0, cells: []),
                              revealed: 0, placeholder: true)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.amber.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.amber.opacity(0.22), lineWidth: 1))
        )
    }

    // MARK: 输入区

    private var controls: some View {
        VStack(spacing: 14) {
            HStack(spacing: 9) {
                ForEach(PegColor.allCases, id: \.self) { color in
                    Button {
                        vm.fill(color)
                    } label: {
                        PegView(color: color, size: 40)
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.locked || vm.outcome != nil)
                }
            }
            HStack(spacing: 10) {
                Button("清 空") { vm.clearCurrent() }
                    .buttonStyle(GhostButtonStyle())
                    .disabled(vm.locked || vm.outcome != nil)
                Button("确 认") {
                    Task { await vm.submit() }
                }
                .buttonStyle(PrimaryButtonStyle(disabled: !vm.canSubmit))
                .disabled(!vm.canSubmit)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }

    // MARK: 结算弹层(§4.10)

    @ViewBuilder private var sheet: some View {
        VStack(spacing: 14) {
            switch vm.outcome {
            case .win(let stars):
                StarsView(count: stars, big: true)
                Text("破译成功!").font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(Theme.text1)
                Text("\(vm.level.displayID) · \(vm.guessesUsed) 次破译")
                    .font(.system(size: 13)).foregroundStyle(Theme.text2)
                answerLine
                HStack(spacing: 10) {
                    Button("重玩") {
                        vm.restart()
                        sheetPresented = false
                    }.buttonStyle(GhostButtonStyle())
                    Button("完成") { dismiss() }.buttonStyle(PrimaryButtonStyle())
                }
            case .lose:
                Text("第 7 行 · 未破译")
                    .font(.system(size: 11)).foregroundStyle(Theme.danger)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().strokeBorder(Theme.danger.opacity(0.35), lineWidth: 1))
                Text("差一步!").font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(Theme.text1)
                Text("密码机器咯咯笑了 —— 再试一次,你已经有不少线索了")
                    .font(.system(size: 13)).foregroundStyle(Theme.text2)
                HStack(spacing: 10) {
                    Button("查看答案") { vm.revealAnswer() }.buttonStyle(GhostButtonStyle())
                    Button("重试本关") {
                        vm.restart()
                        sheetPresented = false
                    }.buttonStyle(PrimaryButtonStyle())
                }
            case .revealed:
                Text("答案揭示").font(.system(size: 11)).foregroundStyle(Theme.text2)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().strokeBorder(Theme.line, lineWidth: 1))
                Text("密码是").font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(Theme.text1)
                answerLine
                Text("可在设置中关闭答案显示")
                    .font(.system(size: 12)).foregroundStyle(Theme.text3)
                Button("再试一次") {
                    vm.restart()
                    sheetPresented = false
                }.buttonStyle(PrimaryButtonStyle())
            case nil:
                EmptyView()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 42)
        .frame(maxWidth: .infinity)
        .background(
            Rectangle()
                .fill(LinearGradient(colors: [Theme.color(0x1A202A), Theme.color(0x12161D)],
                                     startPoint: .top, endPoint: .bottom))
                .ignoresSafeArea()
        )
        .presentationDetents([.height(360)])
    }

    private var answerLine: some View {
        HStack(spacing: 10) {
            Text("答案").font(.system(size: 12)).foregroundStyle(Theme.text3)
            ForEach(vm.answer.indices, id: \.self) { i in
                PegView(color: vm.answer[i])
            }
        }
    }
}
