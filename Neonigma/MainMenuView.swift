import SwiftUI
import Core

struct MainMenuView: View {
    @Environment(AppModel.self) private var app
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button { app.path.append(.settings) } label: {
                        Image(systemName: "gearshape").frame(width: 44, height: 44)
                    }.accessibilityLabel("设置").accessibilityIdentifier("settings")
                }
                VStack(spacing: 14) {
                    HStack(spacing: 8) {
                        ForEach([PegColor.red, .blue, .purple, .yellow], id: \.self) { PegView(color: $0, size: 34) }
                    }.accessibilityHidden(true)
                    Text("霓虹密码机").font(.largeTitle.weight(.heavy))
                    Text("NEONIGMA").font(.caption.monospaced()).kerning(5).foregroundStyle(Theme.text2)
                }
                VStack(spacing: 12) {
                    Button { app.requestLevel(app.store.state.solo?.levelID ?? 1) } label: {
                        card("play.fill", title: app.store.state.solo.map { "继续闯关 · \(LevelStore.level(id: $0.levelID).displayID)" } ?? "开始闯关")
                    }.accessibilityIdentifier("continueGame")
                    Button { app.path.append(.levels(.easy)) } label: { card("target", title: "简单闯关") }
                        .accessibilityIdentifier("easyLevels")
                    Button { app.path.append(.levels(.advanced)) } label: { card("puzzlepiece", title: "进阶闯关") }
                        .accessibilityIdentifier("advancedLevels")
                    Button { app.duoPresented = true } label: { card("person.2.fill", title: "双人对战") }
                        .accessibilityIdentifier("duo")
                    card("calendar", title: "每日挑战", unavailable: true)
                }.buttonStyle(.plain)
                Text("霓虹密码机 Neonigma · M2").font(.caption).foregroundStyle(Theme.text2)
            }.padding(.horizontal, 16).padding(.bottom, 24).frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Theme.text1)
        .background(Theme.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
    private func card(_ icon: String, title: String, unavailable: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title3.bold()).foregroundStyle(Theme.text2)
                .frame(width: 46, height: 46).background(Theme.panel2, in: RoundedRectangle(cornerRadius: 8))
            Text(title).font(.headline).multilineTextAlignment(.leading)
            Spacer(minLength: 4)
            if unavailable { Text("即将推出").font(.caption).foregroundStyle(Theme.text2) }
            else { Image(systemName: "chevron.right").foregroundStyle(Theme.text2) }
        }.padding(16).background(Theme.panel, in: RoundedRectangle(cornerRadius: 10))
            .accessibilityElement(children: .combine)
    }
}
