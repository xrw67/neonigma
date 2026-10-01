#!/usr/bin/env swift
// App 图标生成器(霓虹密码机 Neonigma,方案 A「2×2 发光灯珠」)
// 宿主 macOS 运行:swift tools/gen_icon.swift [--output <png>] [--preview <png>]
// 注意:不放入 Core 包 —— AppKit/CoreGraphics 依赖会破坏 ubuntu CI 的 swift build。
// 规格:1024×1024、sRGB、无 alpha(App Store 硬性要求);色值取自 docs/视觉设计文档.md §3.1。

import AppKit
import Foundation

// ---------- 参数 ----------
var outputPath = "Neonigma/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
var previewPath: String? = nil
let args = CommandLine.arguments
if let i = args.firstIndex(of: "--output"), i + 1 < args.count { outputPath = args[i + 1] }
if let i = args.firstIndex(of: "--preview"), i + 1 < args.count { previewPath = args[i + 1] }

// ---------- 颜色 token(VDD §3.1 / §3.3) ----------
func rgb(_ hex: UInt32) -> (CGFloat, CGFloat, CGFloat) {
    (CGFloat((hex >> 16) & 0xFF) / 255, CGFloat((hex >> 8) & 0xFF) / 255, CGFloat(hex & 0xFF) / 255)
}
func cgcolor(_ c: (CGFloat, CGFloat, CGFloat), _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: c.0, green: c.1, blue: c.2, alpha: a)
}
struct PegToken { let base: (CGFloat, CGFloat, CGFloat); let hi: (CGFloat, CGFloat, CGFloat); let lo: (CGFloat, CGFloat, CGFloat) }

let pegs: [PegToken] = [   // 上排:红、蓝;下排:黄、紫(与 design/ favicon 一致)
    PegToken(base: rgb(0xE5484D), hi: rgb(0xFF8A8E), lo: rgb(0x7E1A20)),
    PegToken(base: rgb(0x0091FF), hi: rgb(0x6BC1FF), lo: rgb(0x004E8C)),
    PegToken(base: rgb(0xFFC53D), hi: rgb(0xFFE29A), lo: rgb(0x8F6A0A)),
    PegToken(base: rgb(0x8E4EC6), hi: rgb(0xC493F0), lo: rgb(0x4C2178)),
]
let bgBase = rgb(0x0E1116)      // 屏内底
let bgLift = rgb(0x18202E)      // 渐晕中心(略亮)
let bgEdge = rgb(0x090C11)      // 渐晕边缘

// ---------- 画布 ----------
// noneSkipLast = RGBX 像素格式:alpha 恒为 255,ImageIO 编码 PNG 时不写 alpha 通道
//(App Store 对图标透明通道零容忍;premultipliedLast 上下文则必须二次去 alpha)。
let px = 1024
let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!
guard let ctx = CGContext(data: nil, width: px, height: px,
                          bitsPerComponent: 8, bytesPerRow: 0, space: sRGB,
                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    fatalError("无法创建 CGContext")
}
let options: CGGradientDrawingOptions = [.drawsBeforeStartLocation, .drawsAfterEndLocation]

// ---------- 背景:哑光深底 + 径向渐晕 ----------
ctx.setFillColor(cgcolor(bgBase))
ctx.fill(CGRect(x: 0, y: 0, width: px, height: px))
let vignette = CGGradient(colorsSpace: sRGB, colors: [
    cgcolor(bgLift), cgcolor(bgBase), cgcolor(bgEdge),
] as CFArray, locations: [0.0, 0.55, 1.0])!
ctx.drawRadialGradient(vignette,
                       startCenter: CGPoint(x: 512, y: 552), startRadius: 0,
                       endCenter: CGPoint(x: 512, y: 512), endRadius: 780,
                       options: options)

// ---------- 2×2 灯珠 ----------
let margin: CGFloat = 128
let gap: CGFloat = 72
let side = (CGFloat(px) - margin * 2 - gap) / 2          // 348
let corner = side * 12 / 44 * 1.08                        // 呼应色珠圆角比例,略圆一点

func drawPeg(_ token: PegToken, at origin: CGPoint) {
    let rect = CGRect(origin: origin, size: CGSize(width: side, height: side))
    let path = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)

    // 外辉光:两层柔和投影(先画带投影的底色填充,再关投影画渐变)
    ctx.saveGState()
    ctx.addPath(path)
    ctx.setShadow(offset: .zero, blur: 130, color: cgcolor(token.base, 0.28))
    ctx.setFillColor(cgcolor(token.base))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(path)
    ctx.setShadow(offset: .zero, blur: 48, color: cgcolor(token.base, 0.50))
    ctx.setFillColor(cgcolor(token.base))
    ctx.fillPath()
    ctx.restoreGState()

    // 主体:三值径向渐变(锚点左上,VDD §3.1)
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let gradient = CGGradient(colorsSpace: sRGB, colors: [
        cgcolor(token.hi), cgcolor(token.base), cgcolor(token.lo),
    ] as CFArray, locations: [0.0, 0.55, 1.0])!
    let anchor = CGPoint(x: rect.minX + side * 0.30, y: rect.maxY - side * 0.18)
    ctx.drawRadialGradient(gradient,
                           startCenter: anchor, startRadius: 0,
                           endCenter: anchor, endRadius: side * 1.30,
                           options: options)

    // 顶部釉面高光(上缘 → 52% 消隐)
    let glaze = CGGradient(colorsSpace: sRGB, colors: [
        CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.34),
        CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.10),
        CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0),
    ] as CFArray, locations: [0.0, 0.35, 0.52])!
    ctx.drawLinearGradient(glaze,
                           start: CGPoint(x: rect.minX, y: rect.maxY),
                           end: CGPoint(x: rect.minX, y: rect.minY + side * 0.48),
                           options: options)

    // 底部压暗
    let shade = CGGradient(colorsSpace: sRGB, colors: [
        CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0),
        CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.30),
    ] as CFArray, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(shade,
                           start: CGPoint(x: rect.minX, y: rect.maxY - side * 0.55),
                           end: CGPoint(x: rect.minX, y: rect.minY),
                           options: options)
    ctx.restoreGState()

    // 内缘细描边(微亮,呼应色珠内阴影反光)
    ctx.addPath(path)
    ctx.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.10))
    ctx.setLineWidth(2)
    ctx.strokePath()
}

let origins = [
    CGPoint(x: margin, y: margin + side + gap),                    // 左上(红)
    CGPoint(x: margin + side + gap, y: margin + side + gap),       // 右上(蓝)
    CGPoint(x: margin, y: margin),                                  // 左下(黄)
    CGPoint(x: margin + side + gap, y: margin),                     // 右下(紫)
]
for (token, origin) in zip(pegs, origins) {
    drawPeg(token, at: origin)
}

guard let cgImage = ctx.makeImage() else { fatalError("CGImage 生成失败") }

// ---------- 输出 ----------
func writePNG(_ image: CGImage, to path: String) throws {
    let rep = NSBitmapImageRep(cgImage: image)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("PNG 编码失败")
    }
    let url = URL(fileURLWithPath: path)
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                            withIntermediateDirectories: true)
    try data.write(to: url)
}

try writePNG(cgImage, to: outputPath)
print("✓ 图标已生成 → \(outputPath)(\(px)×\(px),sRGB,无 alpha)")

if let previewPath {
    let previewPx = 180
    guard let smallCtx = CGContext(data: nil, width: previewPx, height: previewPx,
                                   bitsPerComponent: 8, bytesPerRow: 0, space: sRGB,
                                   bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        fatalError("预览上下文创建失败")
    }
    smallCtx.interpolationQuality = .high
    smallCtx.draw(cgImage, in: CGRect(x: 0, y: 0, width: previewPx, height: previewPx))
    guard let smallImage = smallCtx.makeImage() else { fatalError("预览图生成失败") }
    try writePNG(smallImage, to: previewPath)
    print("✓ 预览已生成 → \(previewPath)(\(previewPx)×\(previewPx))")
}
