import Foundation
import SwiftData

@Model
final class DailyProgress {
    @Attribute(.unique) var id: UUID
    var date: Date // Normalized to start of day
    var wordsLearned: Int
    var wordsReviewed: Int
    var totalStudyTime: TimeInterval // in seconds
    var sessionsCompleted: Int
    var accuracy: Double // Percentage 0-100

    init(date: Date, wordsLearned: Int = 0, wordsReviewed: Int = 0,
         totalStudyTime: TimeInterval = 0, sessionsCompleted: Int = 0, accuracy: Double = 0.0) {
        self.id = UUID()
        // Normalize date to start of day
        let calendar = Calendar.current
        self.date = calendar.startOfDay(for: date)
        self.wordsLearned = wordsLearned
        self.wordsReviewed = wordsReviewed
        self.totalStudyTime = totalStudyTime
        self.sessionsCompleted = sessionsCompleted
        self.accuracy = accuracy
    }
}
