//
//  HomeViewModel.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class HomeViewModel {
    var todayProgress: DailyProgress?
    var userStats: UserStats?
    var userSettings: UserSettings?
    var wordsDueForReview: Int = 0
    var progressPercentage: Double = 0.0

    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadData()
    }

    func loadData() {
        loadTodayProgress()
        loadUserStats()
        loadUserSettings()
        calculateWordsDue()
        calculateProgress()
    }

    private func loadTodayProgress() {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyProgress>(
            predicate: #Predicate { $0.date == today }
        )

        do {
            let results = try modelContext.fetch(descriptor)
            todayProgress = results.first

            // Create today's progress if it doesn't exist
            if todayProgress == nil {
                let newProgress = DailyProgress(
                    date: today,
                    wordsLearned: 0,
                    wordsReviewed: 0,
                    totalStudyTime: 0,
                    sessionsCompleted: 0,
                    accuracy: 0.0
                )
                modelContext.insert(newProgress)
                try? modelContext.save()
                todayProgress = newProgress
            }
        } catch {
            print("Error loading today's progress: \(error)")
        }
    }

    private func loadUserStats() {
        let descriptor = FetchDescriptor<UserStats>()

        do {
            let results = try modelContext.fetch(descriptor)
            userStats = results.first

            // Create user stats if they don't exist
            if userStats == nil {
                let newStats = UserStats(
                    currentStreak: 0,
                    longestStreak: 0,
                    lastStudyDate: nil,
                    totalWordsLearned: 0,
                    totalStudyTime: 0,
                    unlockedAchievements: []
                )
                modelContext.insert(newStats)
                try? modelContext.save()
                userStats = newStats
            }
        } catch {
            print("Error loading user stats: \(error)")
        }
    }

    private func loadUserSettings() {
        let descriptor = FetchDescriptor<UserSettings>()

        do {
            let results = try modelContext.fetch(descriptor)
            userSettings = results.first

            // Create user settings if they don't exist
            if userSettings == nil {
                let newSettings = UserSettings()
                modelContext.insert(newSettings)
                try? modelContext.save()
                userSettings = newSettings
            }
        } catch {
            print("Error loading user settings: \(error)")
        }
    }

    private func calculateWordsDue() {
        let today = Date()
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate { word in
                word.nextReviewDate != nil && word.nextReviewDate! <= today
            }
        )

        do {
            let results = try modelContext.fetch(descriptor)
            wordsDueForReview = results.count
        } catch {
            print("Error calculating words due: \(error)")
            wordsDueForReview = 0
        }
    }

    private func calculateProgress() {
        guard let todayProgress = todayProgress,
              let dailyGoal = userSettings?.dailyGoal,
              dailyGoal > 0 else {
            progressPercentage = 0.0
            return
        }

        let totalStudied = todayProgress.wordsLearned + todayProgress.wordsReviewed
        progressPercentage = min(Double(totalStudied) / Double(dailyGoal), 1.0)
    }

    func refresh() {
        loadData()
    }
}
