# AGENTS.md — Neonigma(霓虹密码机)

## 项目概览

复刻掌上解谜玩具「计客超级密码机」(GiiKER Super Decoder)玩法的 iOS 游戏,本质是 Mastermind(珠玑妙算)电子版:4×7 棋盘、7 色取 4 不重复、7 步内破译 4 位颜色密码。产品定名**霓虹密码机 / Neonigma**,工程代号 SuperDecoder。

**当前状态:M2 实现与验收中(2026-10-02)**。Core 引擎、600 关表、单存档续玩、章节选关、双人对战、教程及设置已接入;具体验收状态见 docs/M2验收记录.md。英语、统计页面属 M3,每日挑战/联网功能后续实施。

## 目录结构

```
docs/需求文档.md       # PRD(含 M2 修订,权威规格,改动功能前必读)
docs/视觉设计文档.md    # VDD v2.0(暖色纸面 token/组件/动效规范,改动视觉前必读)
docs/技术选型.md        # 技术选型定稿(冲突处以它为准)
Core/                  # 本地 SPM 包(纯 Swift,Swift 6 语言模式)
  Sources/Core/        # 规则引擎 evaluate / SplitMix64 / 关卡生成 / 求解器
  Sources/GenLevels/   # swift run GenLevels → 生成 600 关 JSON
  Sources/GenSounds/   # swift run GenSounds → 程序化合成 5 个音效 WAV
  Sources/Validate/    # swift run Validate → CI 门槛(等价性 + 可解性)
  Tests/CoreTests/     # Swift Testing(含 840×2401 全枚举)
Neonigma/              # App 源码(Xcode 同步文件夹;Resources/ 内关卡表与音效随包内置)
Neonigma.xcodeproj/    # Xcode 27 工程(objectVersion 77,XML plist 格式)
tools/gen_pbxproj.py   # 生成 project.pbxproj 的脚本(见下方工程 gotcha)
.github/workflows/     # CI:ubuntu 跑引擎测试 + macOS 跑 iOS 构建
NeonigmaTests/         # App 状态机/SwiftData/时钟测试
NeonigmaUITests/       # 独立测试存档的 UI 冒烟
.zcode/plans/          # 会话计划文件
```

## 权威规则:先读 PRD

`docs/需求文档.md` 是唯一权威规格。改动玩法、视觉、关卡相关内容前必读对应章节:

- **§3.4 提示算法**:`evaluate(code, guess)` 两遍判定——先算对位(绿)并消费,再从左到右配错位(白)。直接提示(逐格)与间接提示(聚合计数)必须严格等价,这是验收项 A4。Core 规则引擎是唯一实现来源,任何改动须与 PRD 保持一致。
- **§6.2 色彩**:7 色色值以 PRD 与当前视觉设计文档为准,App token 在 `Neonigma/Theme.swift` 中维护。
- **`docs/视觉设计文档.md`**:视觉真源的文字化规范(token 表 / 组件规格 / S1–S12 屏清单 / 动效)。改视觉时以它为准:当前暖色纸面规范与 App token 为准,旧 design/ 已删除;间接提示徽章为**固定 2×2** 排布(2026-10-01 定稿)。
- **§1.3 合规红线**:「计客」「GiiKER」「超级密码机 Super Decoder」是注册商标,游戏名称、图标、美术、宣传物料**不得使用或模仿**;玩法机制可自由实现,视觉须原创。
- **§3.6 随机与确定性**:关卡禁用系统随机数,用带种子 PRNG(SplitMix64),seed = 关卡全局编号,离线生成 600 关查找表随包内置。

## 当前产品约束

- 固定浅色暖色纸面风格,纯色色珠、无辉光/渐变。背景 #FAF8EF,操作色 #E85D3F。
- 已取消关卡星级与色盲辅助,不得重新引入。
- 单人仅保存最近一局,跨重启恢复;替换未完成存档需确认。
- 双人后台暂停并遮挡内容,返回需继续;比分与秘密仅当前会话保存。
- 失败答案设置仅控制查看入口,不自动揭示。
- design/ 已删除,不恢复旧稿;视觉以 docs/视觉设计文档.md 为准。

## iOS 工程(M2)

技术栈与决策以 `docs/技术选型.md` 为准(PRD §7 为最初建议,冲突处以技术选型为准)。常用命令(仓库根执行):

```bash
swift test --package-path Core                        # 引擎测试(Swift Testing)
swift run --package-path Core GenLevels               # 重新生成 Neonigma/Resources/levels.json
swift run --package-path Core Validate                # CI 门槛:等价性 + 600 关可解性
swift run --package-path Core GenSounds               # 重新合成音效 WAV
swift tools/gen_icon.swift --preview /tmp/icon.png    # 重新生成 App 图标(AppIcon.appiconset)
```

工程 gotcha(重要):

- **xcode-select 当前指向 CommandLineTools**:iOS 构建需 `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` 前缀,或用户执行 `sudo xcode-select -s /Applications/Xcode.app` 后直接用 xcodebuild。
- **project.pbxproj 是 XML plist**,由 `tools/gen_pbxproj.py` 生成(标量必须全字符串、本地包用 `XCLocalSwiftPackageReference`+`relativePath`、包引用不得挂在主分组 children)。Xcode 打开保存后会改写为 OpenStep 格式——属正常;若工程描述损坏,改 python 脚本再 `python3 tools/gen_pbxproj.py` 重新生成,不要手补 OpenStep。
- **levels.json、Sounds/*.wav、AppIcon icon-1024.png 是生成产物但随包入库**(确定性生成);改生成器后必须重跑对应工具并提交,CI 会 diff 关卡表字节一致性。
- 图标生成脚本用 Quartz `noneSkipLast` 上下文保证 PNG 无 alpha(App Store 硬性要求);它依赖 macOS 宿主,故放 tools/ 而非 Core 包(ubuntu CI 会编译失败)。
- 模拟器 runtime:iOS 17.0 与 iOS 27.0(2026-10-01 起);最低版本回归用 iOS 17 设备(如 iPhone 15 / iPhone SE 3)。
- 调试直进对局页:`xcrun simctl launch <udid> com.xrw67.neonigma -game 101`(App 的 `-game <1...600>` 启动参数钩子)。

## 其他

- 文档与注释均使用简体中文;游戏文案将走 String Catalogs(首发简中 + 英语,M3)。
- 仓库为 git(本地),暂无远程;CI(双轨:ubuntu 引擎 + macos-26 构建)在推送 GitHub 后生效。
