#!/usr/bin/env swift
// App 图标生成器(霓虹密码机 Neonigma,暖色纸面 2×2 四珠标志)
// 宿主 macOS 运行:swift tools/gen_icon.swift [--output <png>] [--preview <png>]
// 注意:不放入 Core 包 —— AppKit/CoreGraphics 依赖会破坏 ubuntu CI 的 swift build。
// 规格:1024×1024、sRGB、无 alpha(App Store 硬性要求);色值取自 docs/视觉设计文档.md。

import AppKit
import Foundation

// ---------- 参数 ----------
var outputPath = "Neonigma/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
var previewPath: String? = nil
let args = CommandLine.arguments
if let i = args.firstIndex(of: "--output"), i + 1 < args.count { outputPath = args[i + 1] }
if let i = args.firstIndex(of: "--preview"), i + 1 < args.count { previewPath = args[i + 1] }

// ---------- 颜色 token(VDD §2) ----------
func rgb(_ hex: UInt32) -> (CGFloat, CGFloat, CGFloat) {
    (CGFloat((hex >> 16) & 0xFF) / 255, CGFloat((hex >> 8) & 0xFF) / 255, CGFloat(hex & 0xFF) / 255)
}
func cgcolor(_ c: (CGFloat, CGFloat, CGFloat), _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: c.0, green: c.1, blue: c.2, alpha: a)
}
struct PegToken { let base: (CGFloat, CGFloat, CGFloat) }

let pegs: [PegToken] = [   // 上排:红、蓝;下排:黄、紫
    PegToken(base: rgb(0xE97868)),
    PegToken(base: rgb(0x6A9EC8)),
    PegToken(base: rgb(0xEDCD62)),
    PegToken(base: rgb(0xAB89BC)),
]
let background = rgb(0xFAF8EF)
let border = rgb(0xC9BDAD)

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
// ---------- 背景:奶油白纯色 ----------
ctx.setFillColor(cgcolor(background))
ctx.fill(CGRect(x: 0, y: 0, width: px, height: px))

// ---------- 2×2 灯珠 ----------
let margin: CGFloat = 128
let gap: CGFloat = 72
let side = (CGFloat(px) - margin * 2 - gap) / 2          // 348
let corner = side * 12 / 44 * 1.08                        // 呼应色珠圆角比例,略圆一点

func drawPeg(_ token: PegToken, at origin: CGPoint) {
    let rect = CGRect(origin: origin, size: CGSize(width: side, height: side))
    let path = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)

    ctx.addPath(path)
    ctx.setFillColor(cgcolor(token.base))
    ctx.fillPath()

    // 暖灰细描边,在奶油色背景上保持边界清晰。
    ctx.addPath(path)
    ctx.setStrokeColor(cgcolor(border))
    ctx.setLineWidth(3)
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
