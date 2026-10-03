import SwiftUI
import Core

struct PaletteView: View {
    var enabled = true
    let onSelect: (PegColor) -> Void
    var body: some View {
        HStack(spacing: 0) {
            ForEach(PegColor.allCases, id: \.self) { color in
                Button { onSelect(color) } label: { PegView(color: color, size: 40).frame(width: 44, height: 44) }
                    .buttonStyle(.plain).disabled(!enabled)
                    .accessibilityLabel(color.spokenName).accessibilityIdentifier("color-\(color.rawValue)")
            }
        }
    }
}

struct PrivacyCover: View {
    let title: String
    let actionTitle: String
    let action: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "hand.raised.fill").font(.largeTitle).accessibilityHidden(true)
            Text(title).font(.title2.bold()).multilineTextAlignment(.center)
            Button(actionTitle, action: action).buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("privacyContinue")
        }.padding(32).frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.bg.ignoresSafeArea()).foregroundStyle(Theme.text1)
    }
}

struct AdvancedHelpView: View {
    let onContinue: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Text("进阶提示怎么看").font(.title2.bold())
            IndirectBadge(evaluation: CodeBreakerEngine.evaluate(code: [.red, .green, .blue, .yellow], guess: [.red, .blue, .white, .orange]))
                .accessibilityLabel("示例:一个对位,一个错位")
            Text("绿点表示颜色和位置都正确的个数,白点表示颜色正确但位置不对的个数。\n\n只报数量,不报位置。四个提示槽固定按 2×2 排列。")
            Button("明白了,开始闯关", action: onContinue).buttonStyle(PrimaryButtonStyle())
        }.padding(24).foregroundStyle(Theme.text1).presentationBackground(Theme.bg)
    }
}

struct SettingsView: View {
    @Environment(AppModel.self) private var app
    var body: some View {
        Form {
            Section("游戏设置") {
                Toggle("音效", isOn: setting(\.sound)).accessibilityIdentifier("soundSetting")
                Toggle("触觉反馈", isOn: setting(\.haptics))
                Toggle("失败后允许查看答案", isOn: setting(\.allowAnswer)).accessibilityIdentifier("answerSetting")
            }
            Section {
                Button("重放教程") { app.showTutorial(firstRun: false) }
            } footer: { Text("教程重放不会替换最近一局,也不计入成绩。") }
            Section("关于与隐私") {
                Text("霓虹密码机 Neonigma").font(.headline)
                Text("一款以经典 Mastermind 逻辑推理玩法为基础的原创解谜游戏。")
                Text("游戏可离线运行。关卡进度、设置和统计仅保存在本机。本版本无账号、广告、第三方追踪或数据上传。删除应用会删除本机进度。")
            }
        }.scrollContentBackground(.hidden).background(Theme.bg)
            .navigationTitle("设置").navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar)
    }
    private func setting(_ key: WritableKeyPath<PlayerSettings, Bool>) -> Binding<Bool> {
        Binding(get: { app.store.state.settings[keyPath: key] }, set: { value in
            app.store.updateSettings { $0[keyPath: key] = value }
            SoundService.shared.setEnabled(app.store.state.settings.sound)
        })
    }
}

/// 仅播放两秒的轻量彩带,不使用系统随机数或常驻计时器。
struct CelebrationView: View {
    @State private var start = Date()
    @State private var finished = false
    var body: some View {
        Group {
            if !finished {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let t = timeline.date.timeIntervalSince(start)
                        for i in 0..<30 {
                            let x = CGFloat((i * 37) % 100) / 100 * size.width
                            let y = t * (70 + Double(i % 6) * 12) - Double(i % 7) * 20
                            context.fill(Path(CGRect(x: x, y: y, width: 6, height: 11)), with: .color(Theme.pegBase(PegColor.allCases[i % 7])))
                        }
                    }
                }.frame(height: 220)
            }
        }.task {
            start = Date()
            try? await Task.sleep(for: .seconds(2))
            finished = true
        }
    }
}
