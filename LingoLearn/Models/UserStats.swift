import Foundation
import SwiftData

@Model
final class UserStats {
    @Attribute(.unique) var id: UUID
    var currentStreak: Int
    var longestStreak: Int
    var lastStudyDate: Date?
    var totalWordsLearned: Int
    var totalStudyTime: TimeInterval // in seconds
    var unlockedAchievements: [String] // Array of achievement IDs

    init(currentStreak: Int = 0, longestStreak: Int = 0, lastStudyDate: Date? = nil,
         totalWordsLearned: Int = 0, totalStudyTime: TimeInterval = 0, unlockedAchievements: [String] = []) {
        self.id = UUID()
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastStudyDate = lastStudyDate
        self.totalWordsLearned = totalWordsLearned
        self.totalStudyTime = totalStudyTime
        self.unlockedAchievements = unlockedAchievements
    }
}
