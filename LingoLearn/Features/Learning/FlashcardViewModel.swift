//
//  FlashcardViewModel.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import Foundation
import SwiftData
import SwiftUI

enum LearningMode {
    case learning  // New words
    case review    // Words due for review
}

@Observable
class FlashcardViewModel {
    var currentWords: [Word] = []
    var currentIndex: Int = 0
    var sessionStats = SessionStats()
    var showSummary = false

    private var modelContext: ModelContext
    private let mode: LearningMode

    var currentWord: Word? {
        guard currentIndex < currentWords.count else { return nil }
        return currentWords[currentIndex]
    }

    var hasMoreCards: Bool {
        currentIndex < currentWords.count
    }

    init(modelContext: ModelContext, mode: LearningMode) {
        self.modelContext = modelContext
        self.mode = mode
        loadWords()
    }

    private func loadWords() {
        // Fetch all words first, then filter in memory
        // (SwiftData #Predicate doesn't support enum comparisons)
        let descriptor = FetchDescriptor<Word>()

        do {
            let allWords = try modelContext.fetch(descriptor)

            switch mode {
            case .learning:
                // Get words that haven't been studied much or have low mastery
                currentWords = allWords.filter { word in
                    word.timesStudied < 3 ||
                    word.masteryLevel == .new ||
                    word.masteryLevel == .learning
                }
                .sorted { ($0.lastStudiedDate ?? .distantPast) < ($1.lastStudiedDate ?? .distantPast) }

            case .review:
                // Get words due for review
                let today = Date()
                currentWords = allWords.filter { word in
                    if let reviewDate = word.nextReviewDate {
                        return reviewDate <= today
                    }
                    return false
                }
                .sorted { ($0.nextReviewDate ?? .distantFuture) < ($1.nextReviewDate ?? .distantFuture) }
            }

            // Limit to 20 words per session
            if currentWords.count > 20 {
                currentWords = Array(currentWords.prefix(20))
            }

            print("Loaded \(currentWords.count) words for \(mode) mode")
        } catch {
            print("Error loading words: \(error)")
        }
    }

    func handleSwipe(direction: SwipeDirection) {
        guard let word = currentWord else { return }

        switch direction {
        case .right: // Know it
            handleKnownWord(word, quality: 4) // Good
            sessionStats.knownCount += 1
        case .left: // Don't know
            handleUnknownWord(word)
            sessionStats.unknownCount += 1
        case .up: // Favorite
            toggleFavorite(word)
            return // Don't advance card for favorite
        }

        sessionStats.totalReviewed += 1
        moveToNextCard()
    }

    private func handleKnownWord(_ word: Word, quality: Int) {
        // Update SM-2 parameters
        let result = SM2Service.shared.calculateNextReview(
            currentEF: word.easeFactor,
            currentInterval: word.interval,
            currentReps: word.repetitions,
            quality: quality
        )

        word.easeFactor = result.easeFactor
        word.interval = result.interval
        word.repetitions = result.repetitions
        word.nextReviewDate = result.nextReviewDate

        // Update study statistics
        word.timesStudied += 1
        word.timesCorrect += 1
        word.lastStudiedDate = Date()

        // Update mastery level
        updateMasteryLevel(word)

        saveWord(word)
    }

    private func handleUnknownWord(_ word: Word) {
        // Reset SM-2 parameters for incorrect answer
        let result = SM2Service.shared.calculateNextReview(
            currentEF: word.easeFactor,
            currentInterval: word.interval,
            currentReps: word.repetitions,
            quality: 0 // Incorrect
        )

        word.easeFactor = result.easeFactor
        word.interval = result.interval
        word.repetitions = result.repetitions
        word.nextReviewDate = result.nextReviewDate

        // Update study statistics
        word.timesStudied += 1
        word.lastStudiedDate = Date()

        saveWord(word)
    }

    private func toggleFavorite(_ word: Word) {
        word.isFavorite.toggle()
        saveWord(word)
    }

    private func updateMasteryLevel(_ word: Word) {
        let accuracy = Double(word.timesCorrect) / Double(max(word.timesStudied, 1))

        if word.timesStudied >= 20 && accuracy >= 0.9 {
            word.masteryLevel = .mastered
        } else if word.timesStudied >= 10 && accuracy >= 0.75 {
            word.masteryLevel = .reviewing
        } else if word.timesStudied > 0 {
            word.masteryLevel = .learning
        } else {
            word.masteryLevel = .new
        }
    }

    private func saveWord(_ word: Word) {
        do {
            try modelContext.save()
        } catch {
            print("Error saving word: \(error)")
        }
    }

    private func moveToNextCard() {
        currentIndex += 1

        if !hasMoreCards {
            // Session complete
            updateDailyProgress()
            updateUserStats()
            showSummary = true
        }
    }

    private func updateDailyProgress() {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyProgress>(
            predicate: #Predicate { $0.date == today }
        )

        do {
            let results = try modelContext.fetch(descriptor)
            let progress = results.first ?? {
                let newProgress = DailyProgress(
                    date: today,
                    wordsLearned: 0,
                    wordsReviewed: 0,
                    totalStudyTime: 0,
                    sessionsCompleted: 0,
                    accuracy: 0.0
                )
                modelContext.insert(newProgress)
                return newProgress
            }()

            if mode == .learning {
                progress.wordsLearned += sessionStats.totalReviewed
            } else {
                progress.wordsReviewed += sessionStats.totalReviewed
            }

            progress.sessionsCompleted += 1

            // Update accuracy
            if sessionStats.totalReviewed > 0 {
                progress.accuracy = sessionStats.accuracy * 100
            }

            try modelContext.save()
        } catch {
            print("Error updating daily progress: \(error)")
        }
    }

    private func updateUserStats() {
        let descriptor = FetchDescriptor<UserStats>()

        do {
            let results = try modelContext.fetch(descriptor)
            guard let stats = results.first else { return }

            // Update total words learned
            stats.totalWordsLearned += sessionStats.knownCount

            // Update streak
            let today = Calendar.current.startOfDay(for: Date())
            if let lastStudy = stats.lastStudyDate {
                let lastStudyDay = Calendar.current.startOfDay(for: lastStudy)
                let daysDifference = Calendar.current.dateComponents([.day], from: lastStudyDay, to: today).day ?? 0

                if daysDifference == 0 {
                    // Same day, no change to streak
                } else if daysDifference == 1 {
                    // Consecutive day
                    stats.currentStreak += 1
                    stats.longestStreak = max(stats.longestStreak, stats.currentStreak)
                } else {
                    // Streak broken
                    stats.currentStreak = 1
                }
            } else {
                // First study
                stats.currentStreak = 1
                stats.longestStreak = 1
            }

            stats.lastStudyDate = Date()

            try modelContext.save()
        } catch {
            print("Error updating user stats: \(error)")
        }
    }

    func reset() {
        currentIndex = 0
        sessionStats = SessionStats()
        showSummary = false
        loadWords()
    }
}

enum SwipeDirection {
    case left, right, up
}

struct SessionStats {
    var totalReviewed: Int = 0
    var knownCount: Int = 0
    var unknownCount: Int = 0

    var accuracy: Double {
        guard totalReviewed > 0 else { return 0 }
        return Double(knownCount) / Double(totalReviewed)
    }
}
