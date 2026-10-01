import SwiftUI
import Core

/// 主菜单(VDD S3):浮动 logo + 继续闯关(第一入口)+ 三模式卡。
/// M1 范围:单人闯关可用;双人为 M2、每日挑战为 P1,置灰占位。
struct MainMenuView: View {
    @State private var bobbing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                    .padding(.top, 28)
                    .padding(.bottom, 24)
                VStack(spacing: 12) {
                    continueCard
                    modeCard(icon: "target", tint: Theme.color(0x8BD39A),
                             bg: Theme.color(0x46A758).opacity(0.14),
                             title: "单人闯关", subtitle: "简单 100 关 + 进阶 500 关,自由跳关") {
                        LevelSelectView()
                    }
                    disabledCard(icon: "person.2.fill", tint: Theme.color(0xC493F0),
                                 bg: Theme.color(0x8E4EC6).opacity(0.16),
                                 title: "双人对战", subtitle: "面对面出题 × 破译,支持限时",
                                 tag: "M2")
                    disabledCard(icon: "calendar", tint: Theme.color(0xFFD37A),
                                 bg: Theme.amber.opacity(0.14),
                                 title: "每日挑战", subtitle: "全网同题 · 打卡纪录",
                                 tag: "P1")
                }
                .padding(.horizontal, 16)
                Spacer(minLength: 32)
                Text("霓虹密码机 Neonigma · v0.1.0 · M1")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.text3)
                    .padding(.bottom, 20)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .navigationDestination(for: Level.self) { level in
            GameView(level: level)
        }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                ForEach(Array([PegColor.red, .blue, .purple, .yellow].enumerated()), id: \.offset) { i, c in
                    PegView(color: c, size: 34)
                        .offset(y: bobbing ? -5 : 4)
                        .animation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2), value: bobbing)
                }
            }
            .onAppear { bobbing = true }
            Text("霓虹密码机")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.text1)
            Text("NEONIGMA")
                .font(.system(size: 11, design: .monospaced))
                .kerning(5)
                .foregroundStyle(Theme.text3)
        }
    }

    /// M1 占位:进度持久化(SwiftData)属 M2,先固定进入 E-001。
    private var continueCard: some View {
        NavigationLink(value: LevelStore.level(id: 1)) {
            modeCardLabel(icon: "play.fill", tint: Theme.color(0x6BC1FF),
                          bg: Theme.color(0x0091FF).opacity(0.15),
                          title: "继续闯关 · E-001", subtitle: "简单模式 · M1 版本",
                          accent: LinearGradient(colors: [Theme.color(0x0091FF).opacity(0.12), Theme.color(0x8E4EC6).opacity(0.10)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing)) {
                Image(systemName: "chevron.right").foregroundStyle(Theme.text3)
            }
        }
        .buttonStyle(.plain)
    }

    private func modeCard<Destination: View>(icon: String, tint: Color, bg: Color,
                                             title: String, subtitle: String,
                                             @ViewBuilder destination: @escaping () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            modeCardLabel(icon: icon, tint: tint, bg: bg, title: title, subtitle: subtitle) {
                Image(systemName: "chevron.right").foregroundStyle(Theme.text3)
            }
        }
        .buttonStyle(.plain)
    }

    private func disabledCard(icon: String, tint: Color, bg: Color,
                              title: String, subtitle: String, tag: String) -> some View {
        modeCardLabel(icon: icon, tint: tint, bg: bg, title: title, subtitle: subtitle) {
            Text(tag)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Theme.text3)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().strokeBorder(Theme.line, lineWidth: 1))
        }
        .opacity(0.55)
    }

    private func modeCardLabel<Trailing: View>(icon: String, tint: Color, bg: Color,
                                               title: String, subtitle: String,
                                               accent: LinearGradient? = nil,
                                               @ViewBuilder trailing: @escaping () -> Trailing) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 46, height: 46)
                .background(RoundedRectangle(cornerRadius: 14).fill(bg))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.text1)
                Text(subtitle).font(.system(size: 12)).foregroundStyle(Theme.text3)
            }
            Spacer()
            trailing()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Theme.panel)
                .overlay {
                    if let accent {
                        RoundedRectangle(cornerRadius: 18).fill(accent)
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.line.opacity(0.6), lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
        )
    }
}
