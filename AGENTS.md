# AGENTS.md — Neonigma(霓虹密码机)

## 项目概览

复刻掌上解谜玩具「计客超级密码机」(GiiKER Super Decoder)玩法的 iOS 游戏,本质是 Mastermind(珠玑妙算)电子版:4×7 棋盘、7 色取 4 不重复、7 步内破译 4 位颜色密码。产品定名**霓虹密码机 / Neonigma**,工程代号 SuperDecoder。

**当前状态:预开发阶段**。仓库尚无 iOS 工程,只有 PRD 与视觉设计稿;Swift/SwiftUI 实现尚未开始。

## 目录结构

```
docs/需求文档.md   # PRD v0.2(权威规格,改动功能前必读)
design/            # 视觉 UI 设计稿 + 可玩 Demo(纯静态 HTML/CSS/JS)
  index.html       # 设计总览页,双击即可离线打开
  css/tokens.css   # 设计变量(7 色/提示态/背景/辉光),与 PRD §6.2 对齐
  css/main.css     # 组件与画廊样式
  js/demo.js       # 可玩 Demo,含真实 evaluate() 判定逻辑
.zcode/plans/      # 会话计划文件
```

## 权威规则:先读 PRD

`docs/需求文档.md` 是唯一权威规格。改动玩法、视觉、关卡相关内容前必读对应章节:

- **§3.4 提示算法**:`evaluate(code, guess)` 两遍判定——先算对位(绿)并消费,再从左到右配错位(白)。直接提示(逐格)与间接提示(聚合计数)必须严格等价,这是验收项 A4。`design/js/demo.js` 中的 `evaluate()` 已实现此规则,任何改动须与 PRD 保持一致。
- **§6.2 色彩与色盲符号**:7 色色值 + 每色唯一几何符号(■▲●◆★✚✿)。`design/css/tokens.css` 的颜色必须与其对齐(该文件计划日后映射为 SwiftUI Asset Catalog)。
- **§1.3 合规红线**:「计客」「GiiKER」「超级密码机 Super Decoder」是注册商标,游戏名称、图标、美术、宣传物料**不得使用或模仿**;玩法机制可自由实现,视觉须原创。
- **§3.6 随机与确定性**:关卡禁用系统随机数,用带种子 PRNG(SplitMix64),seed = 关卡全局编号,离线生成 600 关查找表随包内置。

## design/ 约束

- **零依赖纯静态**:无框架、无构建步骤、无外部字体/图片(全部 CSS 绘制)。不要引入 npm、打包器或 CDN 资源。
- 预览方式:直接用浏览器打开 `design/index.html`(约 11 屏设计稿 + 可玩 Demo,E-001 直接提示,可切换间接提示对比)。
- 手机框尺寸 390×844,对应 iPhone 竖屏。
- 视觉风格为定稿方向 A「霓虹灯珠·复古电子风」:深炭黑底 `#0E1116`、发光圆角色珠、街机机械感;CTA 用琥珀色 `#FFB224`。

## 未来 iOS 工程(尚未创建)

PRD §7 已定技术方案,创建工程时遵循:

- Swift + SwiftUI,最低 iOS 17,SwiftData 持久化;架构分层 `Core/`(纯规则引擎,零 UI 依赖,可单测)/ `Features/` / `Persistence/` / `Services/` / `Resources/`。
- 随仓库脚本 `scripts/gen_levels.swift`(生成 600 关表)与 `scripts/validate.swift`(提示等价性 + 每关 ≤6 次可解性验证),输出作为 CI 门槛。
- 单人模式第 1 行为系统起始线索,玩家最多 6 次猜测;双人模式无起始线索,7 次机会 + 限时。

## 其他

- 文档与注释均使用简体中文;游戏文案走字符串表(首发简中 + 英语)。
- 本目录当前不是 git 仓库。
