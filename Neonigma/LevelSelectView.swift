import SwiftUI
import Core

/// 关卡选择(VDD S4):简单/进阶分段 + 5 列网格 + 自由跳关(FR-L2 / FR-S6)。
/// M1:星级/进度持久化属 M2,当前全部显示为未完成态。
struct LevelSelectView: View {
    @State private var band: Band = .easy

    private var levels: [Level] {
        LevelStore.table.levels.filter { $0.band == band }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("关卡选择").font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.text1)
                Spacer()
                LEDView(text: "★ 0", small: true)
            }
            .padding(.horizontal, 16)
            .frame(height: 46)

            HStack {
                Text(band == .easy ? "简单 · 直接提示" : "进阶 · 间接提示")
                Spacer()
                Text("自由跳关 · 星级随时可刷")
            }
            .font(.system(size: 12))
            .foregroundStyle(Theme.text2)
            .padding(.horizontal, 18)
            .padding(.bottom, 10)

            Picker("模式", selection: $band) {
                Text("简单 · 直接提示").tag(Band.easy)
                Text("进阶 · 间接提示").tag(Band.advanced)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 5), spacing: 9) {
                    ForEach(levels, id: \.self) { level in
                        NavigationLink(value: level) {
                            levelCell(level)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.board))
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private func levelCell(_ level: Level) -> some View {
        VStack(spacing: 2) {
            Text(shortID(level))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.text1)
            StarsView(count: 0)
                .font(.system(size: 9))
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Theme.bg)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.line.opacity(0.6), lineWidth: 1))
        )
    }

    /// 网格格内短编号:E21 / A137(数字屏风格)。
    private func shortID(_ level: Level) -> String {
        level.band == .easy ? "E\(level.id)" : "A\(level.id - 100)"
    }
}
