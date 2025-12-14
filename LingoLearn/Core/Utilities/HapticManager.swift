import UIKit

final class HapticManager {
    static let shared = HapticManager()

    private init() {}

    // Check if device supports haptics
    var isHapticsAvailable: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }

    // Impact haptic feedback
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isHapticsAvailable else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    // Notification haptic feedback
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticsAvailable else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    // Selection haptic feedback
    func selection() {
        guard isHapticsAvailable else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
