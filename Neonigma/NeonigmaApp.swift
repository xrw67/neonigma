import SwiftUI
import Core

@main struct NeonigmaApp: App {
    var body: some Scene {
        WindowGroup {
            AppBootstrapView()
                .preferredColorScheme(.light)
                .tint(Theme.selection)
        }
    }
}

struct AppBootstrapView: View {
    @State private var app: AppModel?
    @State private var loadError: String?
    var body: some View {
        Group {
            if let app { AppRootView(app: app) }
            else if let loadError {
                ContentUnavailableView {
                    Label("无法读取进度", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text("原数据已保留。\n\(loadError)")
                } actions: { Button("重试") { load() } }
            } else { ProgressView("读取进度") }
        }
        .background(Theme.bg.ignoresSafeArea())
        .task { if app == nil { load() } }
    }
    private func load() {
        do {
            var url: URL?
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "-test-store"), i + 1 < args.count,
               let identifier = UUID(uuidString: args[i + 1]) {
                let directory = URL.applicationSupportDirectory.appendingPathComponent("UITests", isDirectory: true)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                url = directory.appendingPathComponent(identifier.uuidString + ".store")
            }
            #endif
            let store = try ProgressStore(url: url, inMemory: url == nil && ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil)
            let model = AppModel(store: store)
            #if DEBUG
            if args.contains("-skip-tutorial") { store.updateSettings { $0.tutorialSeen = true } }
            if let i = args.firstIndex(of: "-game"), i + 1 < args.count, let id = Int(args[i + 1]), (1...600).contains(id) {
                model.openLevel(id)
            } else if !store.state.settings.tutorialSeen { model.showTutorial(firstRun: true) }
            #else
            if !store.state.settings.tutorialSeen { model.showTutorial(firstRun: true) }
            #endif
            app = model
            loadError = nil
        } catch { loadError = error.localizedDescription }
    }
}

struct AppRootView: View {
    @Bindable var app: AppModel
    var body: some View {
        NavigationStack(path: $app.path) {
            MainMenuView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .soloLevels: LevelSelectView()
                    case .settings: SettingsView()
                    case .game:
                        if let game = app.game {
                            GameView(vm: game, allowAnswer: app.store.state.settings.allowAnswer,
                                     onExit: app.leaveGame, onSelection: app.selectLevels, onNext: app.nextLevel)
                                .id(ObjectIdentifier(game))
                        }
                    }
                }
        }
        .environment(app)
        .safeAreaInset(edge: .top) {
            if let error = app.store.errorMessage {
                VStack {
                    Text(error).font(.caption)
                    Button("重试保存") { app.store.persist() }
                }.padding(8).frame(maxWidth: .infinity).background(Theme.panel)
            }
        }
        .alert("替换未完成的对局？", isPresented: Binding(get: { app.replacementLevel != nil }, set: { _ in })) {
            Button("替换并开始", role: .destructive) { app.confirmReplacement() }
            Button("取消", role: .cancel) { app.replacementLevel = nil }
        } message: { Text("当前只保留最近一局。已通关记录会保留。") }
        .sheet(isPresented: Binding(get: { app.advancedLevel != nil }, set: { if !$0 { app.advancedLevel = nil } })) {
            AdvancedHelpView(onContinue: app.confirmAdvancedHelp)
        }
        .fullScreenCover(isPresented: $app.tutorialPresented) {
            TutorialView { app.endTutorial(completed: $0) }.environment(app)
        }
        .fullScreenCover(isPresented: $app.duoPresented) {
            DuoView(onExit: { app.duoPresented = false }).environment(app)
        }
    }
}
