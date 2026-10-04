import SwiftUI
import Core

struct GameView: View {
    @Bindable var vm: GameViewModel
    let allowAnswer: Bool
    var onExit: () -> Void
    var onSelection: (() -> Void)? = nil
    var onNext: (() -> Void)? = nil
    var duoSummary: String? = nil
    var onSwap: (() -> Void)? = nil
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var resultPresented = false
    @State private var exitPrompt = false
    @State private var restartPrompt = false
    @State private var paused = false

    private var isDuo: Bool { vm.configuration.kind == .duo }
    var body: some View {
        ZStack {
            if !paused {
            VStack(spacing: 10) {
                navbar
                HStack {
                    Text(vm.isEasy ? "直接提示" : "间接提示")
                    Spacer()
                    Text("已用 \(vm.guessesUsed)/\(vm.maxGuesses) 次")
                }.font(.subheadline).padding(.horizontal, 16)
                if !vm.isEasy {
                    Text("绿:对位个数 · 白:错位个数 · 只报数量")
                        .font(.caption).foregroundStyle(Theme.text2).padding(.horizontal, 16)
                }
                board
                controls
            }
            }
            if paused {
                PrivacyCover(title: "对局已暂停", actionTitle: "继续") {
                    paused = false
                    vm.resume()
                }
            }
        }
        .foregroundStyle(Theme.text1)
        .background(Theme.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            vm.reduceMotion = reduceMotion
            if scenePhase == .active && !paused { vm.resume() }
            resultPresented = vm.readyForResult
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(100)) } catch { break }
                vm.tick()
            }
        }
        .onDisappear { vm.pause() }
        .onChange(of: reduceMotion) { _, value in vm.reduceMotion = value; if value { vm.finishAnimation() } }
        .onChange(of: vm.readyForResult) { _, ready in if ready { resultPresented = true } }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { vm.pause(); if isDuo { paused = true } }
            else if !isDuo { vm.resume() }
        }
        .alert(isDuo ? "退出双人对战？" : "保存并退出对局？", isPresented: $exitPrompt) {
            Button(isDuo ? "退出" : "保存并退出", role: .destructive) { vm.pause(); onExit() }
            Button("取消", role: .cancel) { if !paused { vm.resume() } }
        } message: { Text(isDuo ? "本次双方比分将清除。" : "可从单人闯关页面继续最近一局。") }
        .alert("重开本关？", isPresented: $restartPrompt) {
            Button("重开", role: .destructive) { vm.restart() }
            Button("取消", role: .cancel) { vm.resume() }
        }
        .sheet(isPresented: $resultPresented) {
            Group {
                if isDuo && paused {
                    PrivacyCover(title: "结果已遮挡", actionTitle: "继续") { paused = false }
                } else { result }
            }
                .interactiveDismissDisabled()
                .presentationDetents([.medium, .large])
                .presentationBackground(Theme.bg)
        }
    }

    private var navbar: some View {
        HStack {
            Button { if !isDuo { vm.pause() }; exitPrompt = true } label: {
                Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).frame(width: 44, height: 44)
            }.accessibilityLabel("返回").accessibilityIdentifier("gameBack")
            Spacer()
            LEDView(text: isDuo ? (vm.remaining.map(durationText) ?? "不限时") : vm.configuration.title,
                    danger: isDuo && (vm.remaining ?? .infinity) <= 30)
                .accessibilityLabel(isDuo ? "剩余时间" : "关卡")
                .accessibilityValue(isDuo ? (vm.remaining.map(durationText) ?? "不限时") : vm.configuration.title)
            Spacer()
            if !isDuo {
                Button { vm.pause(); restartPrompt = true } label: {
                    Image(systemName: "arrow.counterclockwise").font(.system(size: 18, weight: .bold)).frame(width: 44, height: 44)
                }.accessibilityLabel("重开本关").accessibilityIdentifier("restart")
            } else { Color.clear.frame(width: 44, height: 44) }
        }.padding(.horizontal, 12)
    }

    private var board: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { index in row(index).id(index) }
                }.padding(10).background(Theme.board, in: RoundedRectangle(cornerRadius: 10))
                    .frame(maxWidth: 390).frame(maxWidth: .infinity)
            }
            .onChange(of: vm.rows.count) { _, count in proxy.scrollTo(min(6, count), anchor: .bottom) }
            .onAppear { proxy.scrollTo(min(6, vm.rows.count), anchor: .center) }
        }.padding(.horizontal, 12)
    }

    private func row(_ index: Int) -> some View {
        let submitted = index < vm.rows.count
        let editing = index == vm.rows.count && vm.outcome == nil
        return HStack(spacing: 6) {
            VStack(spacing: 2) {
                Text("\(index + 1)").font(.system(size: 12, weight: .bold))
                if index == 0 && vm.configuration.clue != nil { Text("线索").font(.system(size: 9, weight: .bold)) }
            }.frame(width: 26).accessibilityHidden(true)
            VStack(spacing: 5) {
                HStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { col in
                        let color = submitted ? vm.rows[index].guess[col] : (editing ? vm.current[col] : nil)
                        if editing {
                            Button { vm.select(col) } label: {
                                PegView(color: color, selected: vm.selected == col)
                            }.buttonStyle(.plain).disabled(!vm.canEdit)
                                .accessibilityLabel("第 \(index + 1) 行第 \(col + 1) 格")
                                .accessibilityValue("\(color?.spokenName ?? "空白"),\(vm.selected == col ? "已选中" : "未选中")")
                                .accessibilityIdentifier("cell-\(col)")
                                .accessibilityAction(named: "清空此格") { vm.clearCell(col) }
                                .accessibilityAdjustableAction { vm.cycle(col, direction: $0 == .increment ? 1 : -1) }
                                .simultaneousGesture(LongPressGesture(minimumDuration: 0.6).onEnded { _ in vm.clearCell(col) })
                                // 长按后竖滑切色,普通滑动仍留给棋盘滚动。
                                .simultaneousGesture(LongPressGesture(minimumDuration: 0.25).sequenced(before: DragGesture(minimumDistance: 18)).onEnded { value in
                                    if case .second(true, let drag?) = value,
                                       abs(drag.translation.height) > abs(drag.translation.width) * 1.5 {
                                        vm.cycle(col, direction: drag.translation.height < 0 ? 1 : -1)
                                    }
                                })
                        } else {
                            PegView(color: color)
                                .accessibilityLabel("第 \(index + 1) 行第 \(col + 1) 格,\(color?.spokenName ?? "空白")")
                                .accessibilityValue(submitted && vm.isEasy ? vm.rows[index].evaluation.cells[col].spokenName : "")
                        }
                    }
                }
                if vm.isEasy {
                    if submitted { DirectHintDots(evaluation: vm.rows[index].evaluation, revealed: vm.rows[index].revealed).accessibilityHidden(true) }
                    else { Color.clear.frame(height: 9) }
                }
            }.frame(width: 206)
            Group {
                if !vm.isEasy && submitted {
                    IndirectBadge(evaluation: vm.rows[index].evaluation, revealed: vm.rows[index].revealed)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("第 \(index + 1) 行提示:对位 \(vm.rows[index].evaluation.greens) 个,错位 \(vm.rows[index].evaluation.whites) 个")
                } else { Color.clear.accessibilityHidden(true) }
            }.frame(width: 41, height: 41)
        }.padding(.vertical, 5).frame(maxWidth: .infinity)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.selection, lineWidth: editing ? 1.5 : 0))
    }

    private var controls: some View {
        VStack(spacing: 10) {
            PaletteView(enabled: vm.canEdit, onSelect: vm.fill)
            HStack(spacing: 10) {
                Button("清空", action: vm.clearCurrent).buttonStyle(GhostButtonStyle()).disabled(!vm.canEdit)
                Button("确认", action: vm.submit).buttonStyle(PrimaryButtonStyle(disabled: !vm.canSubmit))
                    .disabled(!vm.canSubmit).accessibilityIdentifier("submit")
            }
        }.padding(.horizontal, 16).padding(.bottom, 12).frame(maxWidth: 560).frame(maxWidth: .infinity)
    }

    private var result: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(vm.outcome == .win ? "破译成功!" : vm.outcome == .timeout ? "时间到了" : "这次没猜中")
                    .font(.title.bold()).accessibilityIdentifier("resultTitle")
                Text("\(vm.guessesUsed) 次猜测 · 用时 \(durationText(vm.elapsed))").font(.subheadline)
                if let duoSummary {
                    Text(duoSummary).font(.headline)
                    if let remaining = vm.remaining { Text("剩余 \(durationText(remaining))") }
                }
                if isDuo || vm.outcome == .win || (vm.answerRevealed && allowAnswer) {
                    VStack(spacing: 8) {
                        Text("答案").font(.headline)
                        HStack(spacing: 10) {
                            ForEach(0..<4) { i in PegView(color: vm.answer[i]).accessibilityLabel("第 \(i + 1) 格,\(vm.answer[i].spokenName)") }
                        }
                    }.accessibilityIdentifier("answer")
                }
                if isDuo {
                    Button("换边再来") { resultPresented = false; onSwap?() }.buttonStyle(PrimaryButtonStyle())
                    Button("返回主菜单") { resultPresented = false; onExit() }.buttonStyle(GhostButtonStyle())
                } else {
                    if vm.outcome == .win {
                        let last = vm.configuration.levelID == 100 || vm.configuration.levelID == 600
                        Button(last ? "本模式已完成 · 返回选关" : "下一关") { resultPresented = false; onNext?() }
                            .buttonStyle(PrimaryButtonStyle()).accessibilityIdentifier("nextLevel")
                    } else if allowAnswer && !vm.answerRevealed {
                        Button("查看答案") { vm.revealAnswer(allowed: allowAnswer) }.buttonStyle(GhostButtonStyle())
                    }
                    Button(vm.outcome == .win ? "重玩" : "重试本关") { resultPresented = false; vm.restart() }
                        .buttonStyle(GhostButtonStyle())
                    Button("选关") { resultPresented = false; onSelection?() }.buttonStyle(GhostButtonStyle())
                }
            }.padding(24).frame(maxWidth: 520).frame(maxWidth: .infinity)
        }.foregroundStyle(Theme.text1)
            .overlay(alignment: .top) {
                if vm.outcome == .win && !reduceMotion { CelebrationView().allowsHitTesting(false).accessibilityHidden(true) }
            }
    }
}
