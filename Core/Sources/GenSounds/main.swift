import Foundation

// 程序化合成 5 个游戏音效(PRD §6.3 / 技术选型 §2.8):
// select(选色咔哒)/ place(填色嗒)/ submit(提交锵)/ win(破译上行旋律)/ lose(失败双音)。
// 零采样、零版权风险;输出 16-bit 单声道 WAV,默认写入 App 资源目录。
// 用法:swift run --package-path Core gen-sounds [--output <dir>]

let sampleRate = 44_100.0

// ---------- WAV 写出 ----------
func writeWAV(_ samples: [Float], to path: String) throws {
    let normalized: [Float]
    let peak = samples.map { abs($0) }.max() ?? 1
    normalized = samples.map { peak > 0 ? $0 / peak * 0.82 : 0 }

    var pcm = [Int16](repeating: 0, count: normalized.count)
    for (i, s) in normalized.enumerated() {
        pcm[i] = Int16(max(-32768, min(32767, Int(s * 32767))))
    }
    let data = withUnsafeBytes(of: pcm) { Data($0) }  // 小端宿主假设成立(arm64/x86_64)

    var header = Data()
    func append(_ string: String) { header.append(contentsOf: string.utf8) }
    func append32(_ v: UInt32) { header.append(contentsOf: withUnsafeBytes(of: v) { Data($0) }) }
    func append16(_ v: UInt16) { header.append(contentsOf: withUnsafeBytes(of: v) { Data($0) }) }

    append("RIFF"); append32(UInt32(36 + data.count)); append("WAVE")
    append("fmt "); append32(16); append16(1); append16(1)            // PCM, 单声道
    append32(UInt32(sampleRate)); append32(UInt32(sampleRate * 2))    // byte rate
    append16(2); append16(16)                                          // block align, 位深
    append("data"); append32(UInt32(data.count))

    let url = URL(fileURLWithPath: path)
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                            withIntermediateDirectories: true)
    try header.write(to: url)
    let handle = try FileHandle(forWritingTo: url)
    defer { try? handle.close() }
    try handle.seekToEnd()
    try handle.write(contentsOf: data)
}

// ---------- 合成原语 ----------
func synth(duration: Double, _ f: (Double) -> Float) -> [Float] {
    let n = Int(duration * sampleRate)
    return (0..<n).map { i in f(Double(i) / sampleRate) }
}

/// 正弦分量,带指数衰减起振包络。
func tone(_ freq: Double, at t: Double,
          attack: Double = 0.004, decay: Double,
          gain: Float = 1, partial: Double = 1) -> Float {
    let env: Double
    if t < attack { env = t / attack }
    else { env = exp(-(t - attack) / decay) }
    return gain * Float(env * sin(2 * .pi * freq * partial * t))
}

/// 白噪声瞬态(咔哒的"敲击感")。t 的纯函数:按采样序号哈希,确定性且无全局状态。
func noiseBurst(at t: Double, decay: Double, gain: Float, seed: UInt64) -> Float {
    var x = seed &+ UInt64(bitPattern: Int64(t * sampleRate)) &* 0x9E37_79B9_7F4A_7C15
    x = (x ^ (x >> 30)) &* 0xBF58_476D_1CE4_E5B9
    let unit = Double(Int64(bitPattern: x >> 11)) / Double(Int64.max)
    return gain * Float(exp(-t / decay) * unit)
}

// ---------- 五个音效 ----------

// 1. 选色「咔哒」:高频短促敲击 ~35ms
let select = synth(duration: 0.05) { t in
    tone(2800, at: t, decay: 0.010, gain: 0.55)
        + noiseBurst(at: t, decay: 0.004, gain: 0.30, seed: 0x1234_ABCD)
}

// 2. 填色「嗒」:略低频、稍长 ~45ms
let place = synth(duration: 0.07) { t in
    tone(1900, at: t, decay: 0.014, gain: 0.60)
        + tone(3800, at: t, decay: 0.008, gain: 0.20)
        + noiseBurst(at: t, decay: 0.006, gain: 0.25, seed: 0x2345_BCDA)
}

// 3. 提交「锵」:金属感 = 多个失谐分音叠加,~300ms
let submit = synth(duration: 0.32) { t in
    tone(520, at: t, decay: 0.16, gain: 0.5)
        + tone(520, at: t, decay: 0.12, gain: 0.35, partial: 2.003)
        + tone(520, at: t, decay: 0.09, gain: 0.22, partial: 2.997)
        + tone(520, at: t, decay: 0.06, gain: 0.12, partial: 4.01)
        + noiseBurst(at: t, decay: 0.003, gain: 0.35, seed: 0x3456_CDAB)
}

// 4. 破译成功:10 音上行五声音阶(参照 §6.3「8–12 音符上行小旋律」)
let winScale: [Double] = [523.25, 587.33, 659.25, 783.99, 880.00,
                          1046.5, 1174.7, 1318.5, 1568.0, 1760.0]
let noteLen = 0.10
let win = synth(duration: noteLen * Double(winScale.count) + 0.35) { t in
    var out: Float = 0
    for (i, freq) in winScale.enumerated() {
        let start = Double(i) * noteLen * 0.85   // 轻微重叠,更连贯
        if t >= start {
            out += tone(freq, at: t - start, attack: 0.008, decay: 0.18,
                        gain: 0.34, partial: 2)
                + tone(freq, at: t - start, attack: 0.008, decay: 0.18,
                       gain: 0.30)
        }
    }
    return out
}

// 5. 失败:两音下行(E4 → B3),柔哑
let lose = synth(duration: 0.85) { t in
    var out: Float = 0
    if t < 0.35 {
        out += tone(329.63, at: t, attack: 0.012, decay: 0.22, gain: 0.40)
            + tone(329.63, at: t, attack: 0.012, decay: 0.22, gain: 0.14, partial: 2)
    } else {
        let u = t - 0.35
        out += tone(246.94, at: u, attack: 0.012, decay: 0.38, gain: 0.42)
            + tone(246.94, at: u, attack: 0.012, decay: 0.38, gain: 0.14, partial: 2)
    }
    return out
}

// ---------- 输出 ----------
let args = CommandLine.arguments
var dir = "Neonigma/Resources/Sounds"
if let i = args.firstIndex(of: "--output"), i + 1 < args.count {
    dir = args[i + 1]
}

for (name, samples) in [("select", select), ("place", place), ("submit", submit),
                        ("win", win), ("lose", lose)] {
    let path = "\(dir)/\(name).wav"
    try writeWAV(samples, to: path)
    print("✓ \(path)(\(samples.count) 采样,\(String(format: "%.2f", Double(samples.count) / sampleRate))s)")
}
