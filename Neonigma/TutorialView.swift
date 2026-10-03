import SwiftUI
import Core

struct TutorialView: View {
    let onFinish: (Bool) -> Void
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var success = false
    @State private var step = 0
    @State private var model = GameViewModel(configuration: .tutorial(LevelStore.level(id: 1)))
    @State private var submitted = false
    @State private var message = ""
    private let level = LevelStore.level(id: 1)
    private var evaluation: Evaluation { CodeBreakerEngine.evaluate(code: level.code, guess: level.clue) }
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Text("新手教程 · \(step + 1)/3").font(.headline)
                    Spacer()
                    Button("跳过") { onFinish(false) }.frame(minHeight: 44)
                }
                Text(["点格子,选颜色", "提交后,看懂提示", "利用线索完成破译"][step]).font(.title2.bold())
                if step == 0 {
                    Text("点一个格子,再点下方的颜色。选中的格子会有深棕色边框。")
                    editor
                    Button("下一步") { step = 1 }.buttonStyle(PrimaryButtonStyle(disabled: model.current.allSatisfy { $0 == nil }))
                        .disabled(model.current.allSatisfy { $0 == nil })
                } else if step == 1 {
                    Text("下面是 E001 的起始线索。点击提交,看看它与密码相比的提示。")
                    HStack(spacing: 10) { ForEach(0..<4) { PegView(color: level.clue[$0]).accessibilityLabel(level.clue[$0].spokenName) } }
                    if submitted {
                        DirectHintDots(evaluation: evaluation)
                            .accessibilityLabel(evaluation.cells.map(\.spokenName).joined(separator: ","))
                        Text("绿:颜色和位置都正确\n白:颜色正确,位置不对\n灰:颜色不存在")
                        Button("下一步") { step = 2; model.clearCurrent() }
                            .buttonStyle(PrimaryButtonStyle())
                    } else {
                        Button("提交示例") { submitted = true; app.feedback.play(.submit) }.buttonStyle(PrimaryButtonStyle())
                    }
                } else {
                    Text("保留绿点的位置,换掉不存在的颜色,把白点的颜色移到别处。这次按教学提示填写,一步完成 E001。")
                    Text("教学提示:从左到右为 " + level.code.map(\.spokenName).joined(separator: "、"))
                        .font(.subheadline).padding(12).background(Theme.panel, in: RoundedRectangle(cornerRadius: 10))
                    editor
                    if !message.isEmpty { Text(message).foregroundStyle(Theme.danger) }
                    Button("确认密码") {
                        if model.current.compactMap({ $0 }) == level.code {
                            model.submit()
                            success = model.outcome == .win
                        } else { message = "再对照一下教学提示,可以点格子修改。" }
                    }.buttonStyle(PrimaryButtonStyle(disabled: model.current.contains(nil))).disabled(model.current.contains(nil))
                }
            }.padding(24).frame(maxWidth: 520).frame(maxWidth: .infinity)
        }.background(Theme.bg.ignoresSafeArea()).foregroundStyle(Theme.text1)
            .onAppear {
                model.reduceMotion = true
                model.feedback = app.feedback.play
                model.resume()
            }
            .onDisappear { model.pause() }
            .disabled(success)
            .overlay {
                if success {
                    VStack(spacing: 20) {
                        Text("破译成功!").font(.largeTitle.bold())
                        if !reduceMotion { CelebrationView() }
                    }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.bg)
                }
            }
            .task(id: success) {
                if success {
                    do { try await Task.sleep(for: .milliseconds(reduceMotion ? 200 : 1000)) } catch { return }
                    onFinish(true)
                }
            }
    }
    private var editor: some View {
        VStack(spacing: 20) {
            HStack(spacing: 10) {
                ForEach(0..<4) { i in
                    Button { model.select(i) } label: { PegView(color: model.current[i], selected: model.selected == i) }
                        .accessibilityLabel("教学第 \(i + 1) 格").accessibilityValue(model.current[i]?.spokenName ?? "空白")
                        .accessibilityIdentifier("tutorialCell-\(i)")
                }
            }
            PaletteView { color in
                model.fill(color)
            }
        }
    }
}
