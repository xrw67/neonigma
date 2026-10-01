import SwiftUI
import Core

@main
struct NeonigmaApp: App {

    /// 调试/UI 测试钩子:`-game <全局编号>` 直进对局页(如 `xcrun simctl launch ... com.xrw67.neonigma -game 101`)。
    static var debugLaunchLevel: Level? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-game"), i + 1 < args.count,
              let id = Int(args[i + 1]), (1...LevelTable.count).contains(id) else { return nil }
        return LevelStore.level(id: id)
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if let level = Self.debugLaunchLevel {
                    GameView(level: level)
                } else {
                    MainMenuView()
                }
            }
            .preferredColorScheme(.dark)
            .tint(Theme.amber)
        }
    }
}
