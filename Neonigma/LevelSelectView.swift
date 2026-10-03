import SwiftUI
import Core

struct LevelSelectView: View {
    let band: Band
    @Environment(AppModel.self) private var app
    @State private var expanded: Set<Int> = [0]
    private var levels: [Level] { LevelStore.table.levels.filter { $0.band == band } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(band == .easy ? "直接提示 · 自由跳关" : "间接提示 · 自由跳关")
                    .font(.subheadline).foregroundStyle(Theme.text2)
                if band == .easy { grid(levels) }
                else {
                    ForEach(0..<10) { chapter in
                        DisclosureGroup(isExpanded: Binding(get: { expanded.contains(chapter) }, set: {
                            if $0 { expanded.insert(chapter) } else { expanded.remove(chapter) }
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
        .navigationTitle(band == .easy ? "简单闯关" : "进阶闯关")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .onAppear {
            if band == .advanced, let id = app.store.state.solo?.levelID, id > 100 { expanded.insert((id - 101) / 50) }
        }
    }

    private func grid(_ list: [Level]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
            ForEach(list, id: \.id) { level in
                let completed = app.store.state.completed.contains(level.id)
                let current = app.store.state.solo?.levelID == level.id
                Button { app.requestLevel(level.id) } label: {
                    VStack(spacing: 3) {
                        Text(level.band == .easy ? "E\(level.id)" : "A\(level.id - 100)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                        HStack(spacing: 4) {
                            if completed { Image(systemName: "checkmark") }
                            if current { Image(systemName: "bookmark.fill") }
                        }.font(.caption2).frame(height: 12)
                    }.frame(maxWidth: .infinity).frame(minHeight: 48)
                        .background(Theme.bg, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.selection, lineWidth: current ? 2 : 0))
                }.buttonStyle(.plain).foregroundStyle(Theme.text1)
                    .accessibilityLabel("\(level.displayID),\(completed ? "已通关" : "未通关")\(current ? ",当前存档" : "")")
                    .accessibilityIdentifier("level-\(level.id)")
            }
        }.padding(8).background(Theme.board, in: RoundedRectangle(cornerRadius: 10))
    }
}
