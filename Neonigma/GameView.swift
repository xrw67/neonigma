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
                    .frame(width: 44, height: 44)
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
                    .frame(width: 44, height: 44)
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
                Circle().fill(color).overlay(Circle().strokeBorder(Theme.line, lineWidth: 1)).frame(width: 8, height: 8)
                configuration.title
            }
        }
    }

    // MARK: 棋盘

    private var board: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    boardRow(index)
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.board))
            .frame(maxWidth: 390)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private func boardRow(_ index: Int) -> some View {
        let submitted = index < vm.rows.count
        let editing = index == vm.rows.count && vm.outcome == nil
        return HStack(spacing: 8) {
            VStack(spacing: 2) {
                Text("\(index + 1)").font(.system(size: 12, weight: .bold))
                if index == 0 { Text("线索").font(.system(size: 9, weight: .bold)) }
            }
            .foregroundStyle(Theme.status)
            .frame(width: 26)
            VStack(spacing: 5) {
                HStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { col in
                        PegView(color: submitted ? vm.rows[index].guess[col] : (editing ? vm.current[col] : nil),
                                selected: editing && vm.selected == col)
                            .onTapGesture { if editing { vm.select(col) } }
                    }
                }
                if vm.isEasy {
                    if submitted {
                        DirectHintDots(evaluation: vm.rows[index].evaluation, revealed: vm.rows[index].revealed)
                    } else {
                        Color.clear.frame(height: 9)
                    }
                }
            }
            Group {
                if !vm.isEasy && submitted {
                    IndirectBadge(evaluation: vm.rows[index].evaluation, revealed: vm.rows[index].revealed)
                } else {
                    Color.clear
                }
            }
            .frame(width: 41, height: 41)
        }
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.selection, lineWidth: editing ? 1.5 : 0))
    }

    // MARK: 输入区

    private var controls: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                ForEach(PegColor.allCases, id: \.self) { color in
                    Button {
                        vm.fill(color)
                    } label: {
                        PegView(color: color, size: 40).frame(width: 44, height: 44)
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
                .fill(Theme.bg)
                .ignoresSafeArea()
        )
        .presentationDetents([.medium, .large])
        .presentationBackground(Theme.bg)
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
