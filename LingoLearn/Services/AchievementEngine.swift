//
//  AchievementEngine.swift
//  LingoLearn
//
//  成就判定与解锁。
//

import Foundation
import SwiftData

enum AchievementEngine {
    static func unlockedKeys(context: ModelContext) -> Set<String> {
        let rows = (try? context.fetch(FetchDescriptor<Achievement>())) ?? []
        return Set(rows.map { $0.key })
    }

    static func unlockedAt(context: ModelContext) -> [String: Date] {
        let rows = (try? context.fetch(FetchDescriptor<Achievement>())) ?? []
        return Dictionary(rows.map { ($0.key, $0.unlockedAt) }, uniquingKeysWith: { a, _ in a })
    }

    /// 重新评估全部成就，落库并返回本次新解锁的成就。
    /// - Parameter quizResult: 刚结束的一次练习（用于"完美主义"与"小试牛刀"）
    @discardableResult
    static func evaluate(
        context: ModelContext,
        quizResult: (correct: Int, total: Int)? = nil
    ) -> [AchievementKind] {
        let unlocked = unlockedKeys(context: context)
        let words = StudyService.allWords(context: context)
        let records = StudyService.allRecords(context: context)

        let learned = words.filter { $0.firstLearnedDate != nil }.count
        let mastered = words.filter { $0.status == .mastered }.count
        let favorites = words.filter { $0.isFavorite }.count
        let streak = StudyService.streak(context: context)
        let hasQuizzed = quizResult != nil || records.contains { $0.quizAnswered > 0 }
        let perfect = quizResult.map { $0.total >= 10 && $0.correct == $0.total } ?? false

        var newly: [AchievementKind] = []
        for kind in AchievementKind.allCases where !unlocked.contains(kind.rawValue) {
            let achieved: Bool = switch kind {
            case .firstLesson: learned > 0
            case .firstQuiz: hasQuizzed
            case .streak3: streak >= 3
            case .streak7: streak >= 7
            case .streak30: streak >= 30
            case .learned100: learned >= 100
            case .learned500: learned >= 500
            case .mastered100: mastered >= 100
            case .favorite10: favorites >= 10
            case .perfectQuiz: perfect
            }
            if achieved {
                context.insert(Achievement(key: kind.rawValue))
                newly.append(kind)
            }
        }

        if !newly.isEmpty {
            try? context.save()
        }
        return newly
    }
}
