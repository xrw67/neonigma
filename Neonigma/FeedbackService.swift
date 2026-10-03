import UIKit
import Core

enum FeedbackEvent { case select, place, submit, hint, win, lose, heartbeat }

@MainActor final class FeedbackService {
    private let settings: () -> PlayerSettings
    private let sound: (SoundService.Effect) -> Void
    private let haptic: (FeedbackEvent) -> Void
    init(settings: @escaping () -> PlayerSettings,
         sound: @escaping (SoundService.Effect) -> Void = { SoundService.shared.play($0) },
         haptic: @escaping (FeedbackEvent) -> Void = { FeedbackService.systemHaptic($0) }) {
        self.settings = settings
        self.sound = sound
        self.haptic = haptic
    }
    func play(_ event: FeedbackEvent) {
        let preferences = settings()
        SoundService.shared.setEnabled(preferences.sound)
        if preferences.sound {
            switch event {
            case .select: sound(.select)
            case .place: sound(.place)
            case .submit: sound(.submit)
            case .win: sound(.win)
            case .lose: sound(.lose)
            case .hint, .heartbeat: break
            }
        }
        if preferences.haptics { haptic(event) }
    }
    private static func systemHaptic(_ event: FeedbackEvent) {
        switch event {
        case .win: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .lose: UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .submit: UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        default: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

extension PegColor {
    var spokenName: String { ["红色", "橙色", "黄色", "绿色", "蓝色", "紫色", "白色"][rawValue] }
}

extension CellHint {
    var spokenName: String {
        switch self {
        case .on: "颜色和位置都正确"
        case .wt: "颜色正确,位置不对"
        case .off: "颜色不存在"
        }
    }
}

func durationText(_ seconds: TimeInterval) -> String {
    let whole = max(0, Int(ceil(seconds)))
    return String(format: "%02d:%02d", whole / 60, whole % 60)
}
