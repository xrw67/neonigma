# 霓虹密码机 · Neonigma

[![App Icon](Neonigma/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png)](docs/视觉设计文档.md)

复刻经典掌上解谜玩具「超级密码机」玩法的 iOS 游戏:在一块 4×7 的彩色棋盘上,通过多轮猜测与逐轮反馈的提示灯,在 7 步内推理出隐藏的 4 位颜色密码 —— 经典桌面游戏 **Mastermind(珠玑妙算)** 的电子化版本。

> 玩法机制不受版权保护,可自由实现;「计客 / GiiKER / 超级密码机 Super Decoder」为他人注册商标,本项目名称、图标、美术均为原创,不使用、不模仿(见需求文档 §1.3)。

## 玩法要点

- **密码**:7 色取 4 色、不重复,共 840 种可能;棋盘 7 行,单人模式第 1 行为系统起始线索,玩家最多 **6 次猜测**;
- **两种提示形态**:直接提示(逐格三态:对色对位 / 对色错位 / 不存在,简单模式)与间接提示(行侧聚合计数,只报数量不报位置,进阶模式)—— 两者出自同一判定算法,严格等价;
- **600 关闯关**:简单 100 关 + 进阶 500 关,按起始线索信息量递减设计难度曲线,自由跳关,星级按破译次数结算(≤2 次三星);
- **双人对战**(M2):本地出题 × 破译,支持限时;
- **离线优先**:零网络依赖、零第三方 SDK、零数据收集。

## 项目状态

**M1 进行中**(技术栈与里程碑见[技术选型](docs/技术选型.md)):

| 已完成 | 说明 |
|---|---|
| 规则引擎 | 纯 Swift 6,`evaluate` 与规格逐行为一致;Swift Testing 18 项全绿,含 840×2401 全枚举等价性验证 |
| 600 关卡表 | 确定性生成(SplitMix64,seed = 关卡号),全量经求解器验证 ≤6 次可解 |
| iOS App 骨架 | 主菜单 / 选关 / 双模式对局页,音效程序化合成,App 图标;已在 iOS 17 与 iOS 27 模拟器冒烟 |
| CI | GitHub Actions 双轨:ubuntu 跑引擎测试与关卡表门槛,macos-26 跑 iOS 构建 |

M2 计划:进度持久化(SwiftData)、新手教程、双人模式、设置;M3:打磨与上架(TestFlight)。

## 快速开始

环境:macOS + **Xcode 27**(Swift 6.4);模拟器 runtime 建议 iOS 17.0(最低支持版本)与 iOS 27.0。

### 跑 App

```bash
open Neonigma.xcodeproj      # Xcode 中选 Neonigma scheme + 任一 iPhone 模拟器,⌘R
```

### 命令行(仓库根目录)

```bash
swift test --package-path Core                        # 引擎测试(Swift Testing)
swift run --package-path Core GenLevels               # 生成 600 关查找表(随包内置)
swift run --package-path Core Validate                # 全量验证:等价性 + 可解性(CI 门槛)
swift run --package-path Core GenSounds               # 程序化合成 5 个音效 WAV
swift tools/gen_icon.swift                            # 重新生成 App 图标(1024,sRGB 无 alpha)
python3 tools/gen_pbxproj.py                          # 重新生成 Xcode 工程描述与共享 Scheme
```

> 命令行用 xcodebuild 时需 `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` 前缀(若 `xcode-select` 尚未指向 Xcode.app)。

### 设计稿预览

`design/index.html` 双击离线打开:设计系统 token + 12 屏静态稿 + 可玩 Demo(真实判定逻辑,可切换直接/间接提示)。

## 仓库结构

```
docs/
  需求文档.md        # PRD v0.3(已定稿):玩法规格、功能需求、验收标准
  视觉设计文档.md     # VDD v1.0:token / 组件 / S1–S12 屏 / 动效规范
  技术选型.md         # 定稿:iOS 17 / SwiftUI+Observable / SwiftData / 双轨 CI
Core/               # 本地 SPM 包:规则引擎、关卡生成、求解器、验证工具(Swift 6)
Neonigma/           # App 源码(Features/Services/Resources,同步文件夹工程)
Neonigma.xcodeproj/ # Xcode 27 工程(由 tools/gen_pbxproj.py 生成)
design/             # 视觉设计稿 + 可玩 Demo(纯静态 HTML/CSS/JS)
tools/              # 图标 / 工程描述 生成脚本
.github/workflows/  # CI(ubuntu 引擎 + macos-26 构建)
```

## 设计与工程原则

- **确定性优先**:关卡、音效、图标全部程序化生成、字节级可复现,产物随包入库,CI 校验一致性 —— 任何设备上同一关卡密码一致;
- **运行时零第三方依赖**:契合离线优先与儿童合规(COPPA / GDPR-K,隐私清单齐备);
- **单一判定源**:`Core.evaluate` 是唯一直接/间接提示的实现来源,与浏览器 Demo 互为对照;
- **视觉真源**:`design/` 渲染结果为准,数值规格以 VDD 表格为准,SwiftUI 按 VDD §10 映射。

## 许可

待定(上架前随商业化方案一并确定;当前仅限作者本人使用)。
