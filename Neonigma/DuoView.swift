import SwiftUI
import Observation
import Core

@MainActor @Observable final class DuoSession {
    enum Stage { case setup, handoff, playing }
    var stage = Stage.setup
    var hints = HintMode.direct
    var minutes = 3
    var code: [PegColor?] = Array(repeating: nil, count: 4)
    var selected = 0
    private(set) var setter = 0
    private(set) var scores = [0, 0]
    var game: GameViewModel?
    private var counted: Set<UUID> = []
    var validCode: Bool { code.compactMap { $0 }.count == 4 && Set(code.compactMap { $0 }).count == 4 }
    var duplicate: Bool { let colors = code.compactMap { $0 }; return Set(colors).count != colors.count }
    var summary: String { "玩家 1: \(scores[0]) 分 · 玩家 2: \(scores[1]) 分" }
    func fill(_ color: PegColor) {
        code[selected] = color
        if let next = code.firstIndex(of: nil) { selected = next }
    }
    func prepare(feedback: @escaping (FeedbackEvent) -> Void) {
        guard validCode, let configuration = GameConfiguration.duo(code: code.compactMap { $0 }, hints: hints, seconds: minutes == 0 ? nil : Double(minutes * 60)) else { return }
        let model = GameViewModel(configuration: configuration)
        model.feedback = feedback
        model.onChange = { [weak self, weak model] in
            guard let self, let model, let outcome = model.outcome, self.counted.insert(model.roundID).inserted else { return }
            self.scores[outcome == .win ? 1 - self.setter : self.setter] += 1
        }
        game = model
        code = Array(repeating: nil, count: 4)
        stage = .handoff
    }
    func swap() {
        game?.pause()
        game = nil
        setter = 1 - setter
        selected = 0
        code = Array(repeating: nil, count: 4)
        stage = .setup
    }
}

struct DuoView: View {
    let onExit: () -> Void
    @Environment(AppModel.self) private var app
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session = DuoSession()
    @State private var shield = false
    @State private var exitPrompt = false
    @State private var shake = false
    var body: some View {
        ZStack {
            if !shield {
                switch session.stage {
                case .setup: setup
                case .handoff:
                    PrivacyCover(title: "请交给玩家 \(2 - session.setter)\n准备好后再开始", actionTitle: "开始破译") {
                        session.stage = .playing
                    }
                case .playing:
                    if let game = session.game {
                        GameView(vm: game, allowAnswer: true, onExit: onExit, duoSummary: session.summary, onSwap: session.swap)
                    }
                }
            }
            if shield {
                PrivacyCover(title: "内容已遮挡", actionTitle: "继续") {
                    shield = false
                }
            }
        }.background(Theme.bg.ignoresSafeArea()).foregroundStyle(Theme.text1)
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { if session.stage != .playing { shield = true }; session.game?.pause() }
            }
            .alert("退出双人对战？", isPresented: $exitPrompt) {
                Button("退出", role: .destructive, action: onExit)
                Button("取消", role: .cancel) {}
            } message: { Text("本次双方比分将清除。") }
    }
    private var setup: some View {
        ScrollView {
            VStack(spacing: 22) {
                HStack {
                    Button("返回") { exitPrompt = true }.frame(minHeight: 44)
                    Spacer()
                    Text(session.summary).font(.caption)
                }
                Text("玩家 \(session.setter + 1) 出题").font(.title.bold())
                Text("出题者操作中 · 请另一位玩家暂时回避").font(.subheadline).multilineTextAlignment(.center)
                Picker("提示形态", selection: $session.hints) {
                    Text("直接提示").tag(HintMode.direct)
                    Text("间接提示").tag(HintMode.indirect)
                }.pickerStyle(.segmented)
                HStack(spacing: 14) {
                    ForEach(0..<4) { i in
                        Button { session.selected = i } label: { PegView(color: session.code[i], selected: session.selected == i) }
                            .accessibilityLabel("密码第 \(i + 1) 格")
                            .accessibilityValue(session.code[i]?.spokenName ?? "空白")
                    }
                }.offset(x: shake ? 6 : 0)
                PaletteView { color in
                    session.fill(color)
                    app.feedback.play(.place)
                    if session.duplicate && !reduceMotion {
                        withAnimation(.easeInOut(duration: 0.08).repeatCount(3, autoreverses: true)) { shake = true }
                        Task { try? await Task.sleep(for: .milliseconds(300)); shake = false }
                    }
                }
                Text(session.duplicate ? "密码不能使用重复颜色" : "选择四种不同的颜色")
                    .foregroundStyle(session.duplicate ? Theme.danger : Theme.text2)
                Picker("限时", selection: $session.minutes) {
                    Text("不限时").tag(0)
                    ForEach([1, 3, 5, 10], id: \.self) { Text("\($0) 分钟").tag($0) }
                }.pickerStyle(.menu).frame(minHeight: 44)
                Button("交给破译者") { session.prepare(feedback: app.feedback.play) }
                    .buttonStyle(PrimaryButtonStyle(disabled: !session.validCode)).disabled(!session.validCode)
                    .accessibilityIdentifier("handoff")
                Text("切到后台或锁屏时暂停,返回后点击继续。")
                    .font(.caption).foregroundStyle(Theme.text2)
            }.padding(20).frame(maxWidth: 520).frame(maxWidth: .infinity)
        }
    }
}
