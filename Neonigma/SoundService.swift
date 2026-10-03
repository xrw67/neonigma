import AVFoundation

/// 音效服务(技术选型 §2.8):`.ambient` 会话尊重静音键;启动时预加载全部 AVAudioPlayer。
@MainActor final class SoundService {

    enum Effect: String, CaseIterable {
        case select, place, submit, win, lose
    }

    static let shared = SoundService()

    private var players: [Effect: AVAudioPlayer] = [:]

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        for effect in Effect.allCases {
            guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") else { continue }
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[effect] = player
            }
        }
    }

    private var enabled = true

    func setEnabled(_ value: Bool) {
        enabled = value
        if !value { players.values.forEach { $0.stop() } }
    }

    func play(_ effect: Effect) {
        guard enabled else { return }
        guard let player = players[effect] else { return }
        player.currentTime = 0
        player.play()
    }
}
