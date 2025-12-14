import Foundation
import SwiftData

enum AppearanceMode: String, Codable, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
}

@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var dailyGoal: Int // 10-100, default 20
    var reminderEnabled: Bool
    var reminderTime: Date
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var autoPlayPronunciation: Bool
    var appearanceMode: AppearanceMode
    var questionTimeLimit: Int // seconds per question, default 15

    init(dailyGoal: Int = 20, reminderEnabled: Bool = false, reminderTime: Date = Date(),
         soundEnabled: Bool = true, hapticsEnabled: Bool = true,
         autoPlayPronunciation: Bool = true, appearanceMode: AppearanceMode = .system,
         questionTimeLimit: Int = 15) {
        self.id = UUID()
        self.dailyGoal = min(100, max(10, dailyGoal)) // Clamp between 10-100
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
        self.autoPlayPronunciation = autoPlayPronunciation
        self.appearanceMode = appearanceMode
        self.questionTimeLimit = questionTimeLimit
    }
}
