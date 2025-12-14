//
//  ProgressViewModel.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import Foundation
import SwiftData
import Observation

@Observable
class ProgressViewModel {
    private let modelContext: ModelContext
    private var days: Int = 7

    // Stats
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalWordsLearned: Int = 0
    var totalStudyTime: TimeInterval = 0
    var unlockedAchievements: [String] = []

    // Chart Data
    var chartData: [(date: Date, count: Int)] = []
    var dailyProgressData: [DailyProgress] = []

    // Mastery Distribution
    var newCount: Int = 0
    var learningCount: Int = 0
    var reviewingCount: Int = 0
    var masteredCount: Int = 0

    var formattedTotalStudyTime: String {
        let hours = Int(totalStudyTime) / 3600
        if hours > 0 {
            return "\(hours)小时"
        }
        let minutes = Int(totalStudyTime) / 60
        return "\(minutes)分钟"
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func updatePeriod(_ days: Int) {
        self.days = days
        loadData()
    }

    func loadData() {
        loadStats()
        loadChartData()
        loadMasteryDistribution()
    }

    private func loadStats() {
        // Fetch UserStats
        let statsDescriptor = FetchDescriptor<UserStats>()
        if let stats = try? modelContext.fetch(statsDescriptor).first {
            currentStreak = stats.currentStreak
            longestStreak = stats.longestStreak
            totalWordsLearned = stats.totalWordsLearned
            totalStudyTime = stats.totalStudyTime
            unlockedAchievements = stats.unlockedAchievements
        }
    }

    private func loadChartData() {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!

        // Fetch DailyProgress for the date range
        let descriptor = FetchDescriptor<DailyProgress>(
            predicate: #Predicate { progress in
                progress.date >= startDate && progress.date <= endDate
            },
            sortBy: [SortDescriptor(\.date)]
        )

        if let progressRecords = try? modelContext.fetch(descriptor) {
            dailyProgressData = progressRecords

            // Create chart data points
            var dataPoints: [(date: Date, count: Int)] = []
            var currentDate = startDate

            while currentDate <= endDate {
                let dayStart = calendar.startOfDay(for: currentDate)
                let wordsLearned = progressRecords.first(where: {
                    calendar.isDate($0.date, inSameDayAs: dayStart)
                })?.wordsLearned ?? 0

                dataPoints.append((date: dayStart, count: wordsLearned))
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }

            chartData = dataPoints
        }
    }

    private func loadMasteryDistribution() {
        let descriptor = FetchDescriptor<Word>()
        if let words = try? modelContext.fetch(descriptor) {
            newCount = words.filter { $0.masteryLevel == .new }.count
            learningCount = words.filter { $0.masteryLevel == .learning }.count
            reviewingCount = words.filter { $0.masteryLevel == .reviewing }.count
            masteredCount = words.filter { $0.masteryLevel == .mastered }.count
        }
    }
}
