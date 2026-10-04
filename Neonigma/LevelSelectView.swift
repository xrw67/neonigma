import SwiftUI
import Core

struct LevelSelectView: View {
    @Environment(AppModel.self) private var app
    private var band: Band { app.selectedBand }

    var body: some View {
        @Bindable var app = app
        // 章节闭包使用本次构建的列表,避免模式切换时旧视图读取新模式的数组。
        let levels = LevelStore.table.levels.filter { $0.band == band }
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if app.soloShortcut.levelID != nil {
                    Button(app.soloShortcut.title) { app.performSoloShortcut() }
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityIdentifier("soloShortcut")
                } else {
                    Text(app.soloShortcut.title).font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 8))
                        .accessibilityIdentifier("soloModeComplete")
                }
                Picker("模式", selection: $app.selectedBand) {
                    Text("简单").tag(Band.easy)
                    Text("进阶").tag(Band.advanced)
                }.pickerStyle(.segmented).accessibilityIdentifier("soloBand")
                Text(band == .easy ? "直接提示 · 自由跳关" : "间接提示 · 自由跳关")
                    .font(.subheadline).foregroundStyle(Theme.text2)
                if band == .easy { grid(levels) }
                else {
                    ForEach(0..<10) { chapter in
                        DisclosureGroup(isExpanded: Binding(get: { app.expandedChapters.contains(chapter) }, set: {
                            if $0 { app.expandedChapters.insert(chapter) } else { app.expandedChapters.remove(chapter) }
                        })) {
                            grid(Array(levels[(chapter * 50)..<(chapter * 50 + 50)]))
                        } label: {
                            Text(String(format: "第 %d 章 · A%03d–A%03d", chapter + 1, chapter * 50 + 1, chapter * 50 + 50))
                                .font(.headline).padding(.vertical, 10)
                        }.accessibilityIdentifier("chapter-\(chapter)")
                    }
                }
            }.padding(16).frame(maxWidth: 560).frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("单人闯关")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    private func grid(_ list: [Level]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
            ForEach(list, id: \.id) { level in
                let completed = app.store.state.completed.contains(level.id)
                let current = app.store.state.solo?.levelID == level.id
                Button { app.requestLevel(level.id) } label: {
                    Text("\(level.band == .easy ? level.id : level.id - 100)")
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .frame(maxWidth: .infinity).frame(minHeight: 48)
                        .background(completed ? Theme.levelCompleted : Theme.bg, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.selection, lineWidth: current ? 2 : 0))
                }.buttonStyle(.plain).foregroundStyle(completed ? Theme.hintOn : Theme.text1)
                    .accessibilityLabel("\(level.displayID)，\(completed ? "已通关" : "未通关")\(current ? "，当前存档" : "")")
                    .accessibilityIdentifier("level-\(level.id)")
            }
        }.padding(8).background(Theme.board, in: RoundedRectangle(cornerRadius: 10))
    }
}
