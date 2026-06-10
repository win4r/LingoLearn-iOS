//
//  LingoLearnTests.swift
//  LingoLearnTests
//

import Foundation
import SwiftData
import Testing
@testable import LingoLearn

// MARK: - 工具

@MainActor
private func makeInMemoryContext() throws -> ModelContext {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
        for: Word.self, DailyStudyRecord.self, Achievement.self,
        configurations: config
    )
    return ModelContext(container)
}

@MainActor
private func makeWord(_ en: String, zh: String = "测试释义", category: WordCategory = .cet4) -> Word {
    Word(
        english: en,
        phonetic: "/test/",
        meaning: zh,
        example: "Example sentence for \(en).",
        exampleTranslation: "\(en) 的例句。",
        category: category
    )
}

// MARK: - SM-2 算法

@MainActor
struct SM2Tests {
    @Test func firstSuccessfulReviewGivesOneDay() {
        let result = SM2.review(state: .initial, quality: 5)
        #expect(result.state.repetition == 1)
        #expect(result.nextIntervalDays == 1)
    }

    @Test func secondSuccessfulReviewGivesSixDays() {
        let first = SM2.review(state: .initial, quality: 5)
        let second = SM2.review(state: first.state, quality: 5)
        #expect(second.state.repetition == 2)
        #expect(second.nextIntervalDays == 6)
    }

    @Test func thirdReviewMultipliesByEaseFactor() {
        var state = SM2.State.initial
        for _ in 0..<2 { state = SM2.review(state: state, quality: 5).state }
        let third = SM2.review(state: state, quality: 5)
        // 两次 q=5 后 EF = 2.5 + 0.1 + 0.1 = 2.7；第三次先涨到 2.8 再乘
        #expect(third.nextIntervalDays == Int((6 * third.state.easeFactor).rounded()))
        #expect(third.nextIntervalDays > 6)
    }

    @Test func failureResetsRepetitionAndInterval() {
        var state = SM2.State.initial
        for _ in 0..<3 { state = SM2.review(state: state, quality: 5).state }
        let failed = SM2.review(state: state, quality: 1)
        #expect(failed.state.repetition == 0)
        #expect(failed.nextIntervalDays == 0)
    }

    @Test func easeFactorNeverDropsBelowFloor() {
        var state = SM2.State.initial
        for _ in 0..<20 { state = SM2.review(state: state, quality: 0).state }
        #expect(state.easeFactor >= 1.3)
    }

    @Test func qualityIsClampedToValidRange() {
        let result = SM2.review(state: .initial, quality: 99)
        #expect(result.state.repetition == 1)
        let bad = SM2.review(state: .initial, quality: -5)
        #expect(bad.state.repetition == 0)
    }

    @Test func statusDerivation() {
        #expect(SM2.status(for: .initial, hasBeenStudied: false) == .new)
        #expect(SM2.status(for: .init(repetition: 1, intervalDays: 1, easeFactor: 2.5), hasBeenStudied: true) == .learning)
        #expect(SM2.status(for: .init(repetition: 5, intervalDays: 30, easeFactor: 2.5), hasBeenStudied: true) == .mastered)
        // 间隔够长但重复次数不足 → 仍在学习中
        #expect(SM2.status(for: .init(repetition: 2, intervalDays: 30, easeFactor: 2.5), hasBeenStudied: true) == .learning)
    }

    @Test func gradeQualityMapping() {
        #expect(ReviewGrade.known.quality == 5)
        #expect(ReviewGrade.favorite.quality == 4)
        #expect(ReviewGrade.forgot.quality < 3)
    }
}

// MARK: - 出题引擎

@MainActor
struct QuizEngineTests {
    private var words: [Word] {
        (0..<20).map { makeWord("word\($0)", zh: "释义\($0)") }
    }

    @Test func choiceQuestionHasFourDistinctOptionsContainingAnswer() {
        let all = words
        let question = QuizEngine.makeQuestion(type: .choice, word: all[0], allWords: all)
        #expect(question.options.count == 4)
        #expect(Set(question.options).count == 4)
        #expect(question.options[question.correctIndex] == all[0].meaning)
    }

    @Test func listeningQuestionOptionsAreEnglishWords() {
        let all = words
        let question = QuizEngine.makeQuestion(type: .listening, word: all[3], allWords: all)
        #expect(question.options.count == 4)
        #expect(question.options[question.correctIndex] == all[3].english)
    }

    @Test func spellingQuestionHasNoOptions() {
        let all = words
        let question = QuizEngine.makeQuestion(type: .spelling, word: all[5], allWords: all)
        #expect(question.options.isEmpty)
        #expect(question.correctIndex == -1)
    }

    @Test func makeQuestionsRespectsCountAndAvoidsDuplicateWords() {
        let all = words
        let questions = QuizEngine.makeQuestions(type: .choice, count: 10, allWords: all)
        #expect(questions.count == 10)
        let targets = questions.map { $0.word.english }
        #expect(Set(targets).count == 10)
    }

    @Test func makeQuestionsReturnsEmptyWhenPoolTooSmall() {
        let tiny = (0..<3).map { makeWord("tiny\($0)") }
        #expect(QuizEngine.makeQuestions(type: .choice, count: 5, allWords: tiny).isEmpty)
    }

    @Test func mixedModeProducesQuestionsForEveryTarget() {
        let all = words
        let questions = QuizEngine.makeQuestions(type: nil, count: 12, allWords: all)
        #expect(questions.count == 12)
    }

    @Test func spellingCheckIsCaseAndWhitespaceInsensitive() {
        #expect(QuizEngine.checkSpelling(input: "  Apple ", answer: "apple"))
        #expect(!QuizEngine.checkSpelling(input: "appel", answer: "apple"))
    }
}

// MARK: - 预置词库数据

@MainActor
struct SeedDataTests {
    @Test func bundleContainsAtLeast500UniqueWords() throws {
        let seeds = try WordSeeder.loadSeedWords()
        #expect(seeds.count >= 500)
        let unique = Set(seeds.map { $0.0.en.lowercased() })
        #expect(unique.count >= 500)
        #expect(unique.count == seeds.count, "词库存在重复单词")
    }

    @Test func everySeedWordHasCompleteFields() throws {
        for (seed, _) in try WordSeeder.loadSeedWords() {
            #expect(!seed.en.trimmingCharacters(in: .whitespaces).isEmpty)
            #expect(seed.ph.hasPrefix("/") && seed.ph.hasSuffix("/"), "音标格式异常: \(seed.en)")
            #expect(!seed.zh.isEmpty && !seed.ex.isEmpty && !seed.tr.isEmpty)
        }
    }

    @Test func bothCategoriesAreWellRepresented() throws {
        let seeds = try WordSeeder.loadSeedWords()
        let cet4 = seeds.filter { $0.1 == .cet4 }.count
        let cet6 = seeds.filter { $0.1 == .cet6 }.count
        #expect(cet4 >= 200)
        #expect(cet6 >= 200)
    }

    @Test func seedingIntoEmptyStoreInsertsAllWords() throws {
        let context = try makeInMemoryContext()
        for (seed, category) in try WordSeeder.loadSeedWords() {
            context.insert(Word(
                english: seed.en, phonetic: seed.ph, meaning: seed.zh,
                example: seed.ex, exampleTranslation: seed.tr, category: category
            ))
        }
        try context.save()
        let count = try context.fetchCount(FetchDescriptor<Word>())
        #expect(count >= 500)
    }
}

// MARK: - 学习服务

@MainActor
struct StudyServiceTests {
    @Test func gradingNewWordAsKnownSchedulesTomorrowAndCountsDaily() throws {
        let context = try makeInMemoryContext()
        let word = makeWord("hello")
        context.insert(word)

        StudyService.grade(word, grade: .known, context: context)

        #expect(word.repetition == 1)
        #expect(word.intervalDays == 1)
        #expect(word.status == .learning)
        #expect(word.firstLearnedDate != nil)
        #expect(word.nextReviewDate == Date().startOfDay.addingDays(1))
        #expect(StudyService.todayRecord(context: context).newLearned == 1)
        #expect(StudyService.todayRecord(context: context).reviewed == 0)
    }

    @Test func wordKnownTodayIsNotDueUntilTomorrow() throws {
        // 回归：今天标「认识」→ 明天才复习，不应立即出现在待复习队列
        let context = try makeInMemoryContext()
        let word = makeWord("known-today")
        context.insert(word)
        StudyService.grade(word, grade: .known, context: context)
        #expect(StudyService.dueWords(context: context).isEmpty)
        #expect(StudyService.dueCount(context: context) == 0)
    }

    @Test func gradingForgottenWordKeepsItDueToday() throws {
        let context = try makeInMemoryContext()
        let word = makeWord("tough")
        context.insert(word)

        StudyService.grade(word, grade: .forgot, context: context)

        #expect(word.repetition == 0)
        #expect(word.wrongCount == 1)
        #expect(StudyService.dueWords(context: context).contains { $0.english == "tough" })
    }

    @Test func favoriteGradeMarksFavorite() throws {
        let context = try makeInMemoryContext()
        let word = makeWord("star")
        context.insert(word)
        StudyService.grade(word, grade: .favorite, context: context)
        #expect(word.isFavorite)
        #expect(word.repetition == 1)
    }

    @Test func reviewingExistingWordCountsAsReviewNotNew() throws {
        let context = try makeInMemoryContext()
        let word = makeWord("again")
        context.insert(word)
        StudyService.grade(word, grade: .known, context: context)
        StudyService.grade(word, grade: .known, context: context)
        let record = StudyService.todayRecord(context: context)
        #expect(record.newLearned == 1)
        #expect(record.reviewed == 1)
    }

    @Test func newWordsBatchHonorsRemainingGoalAndOverflow() throws {
        let context = try makeInMemoryContext()
        for i in 0..<30 { context.insert(makeWord("batch\(i)")) }
        try context.save()

        // 目标 20，已学 0，批次上限 10 → 10 个
        #expect(StudyService.newWordsBatch(context: context, dailyGoal: 20).count == 10)

        // 目标 3 → 只给 3 个
        #expect(StudyService.newWordsBatch(context: context, dailyGoal: 3).count == 3)

        // 目标已达成（0 剩余）→ 仍给一组（超额学习）
        let record = StudyService.todayRecord(context: context)
        record.newLearned = 20
        try context.save()
        #expect(StudyService.newWordsBatch(context: context, dailyGoal: 20).count == 10)
    }

    @Test func streakCountsConsecutiveDaysAndSurvivesUnstudiedToday() throws {
        let context = try makeInMemoryContext()
        let today = Date().startOfDay
        // 昨天、前天有学习；今天没有 → streak = 2
        for offset in [1, 2] {
            let record = DailyStudyRecord(day: today.addingDays(-offset))
            record.newLearned = 5
            context.insert(record)
        }
        try context.save()
        #expect(StudyService.streak(context: context) == 2)

        // 今天也学了 → streak = 3
        let todayRecord = DailyStudyRecord(day: today)
        todayRecord.reviewed = 1
        context.insert(todayRecord)
        try context.save()
        #expect(StudyService.streak(context: context) == 3)
    }

    @Test func streakBreaksOnGapDay() throws {
        let context = try makeInMemoryContext()
        let today = Date().startOfDay
        for offset in [0, 1, 3, 4] {
            let record = DailyStudyRecord(day: today.addingDays(-offset))
            record.newLearned = 1
            context.insert(record)
        }
        try context.save()
        #expect(StudyService.streak(context: context) == 2)
    }

    @Test func dailySeriesFillsMissingDaysWithZero() throws {
        let context = try makeInMemoryContext()
        let record = StudyService.todayRecord(context: context)
        record.newLearned = 7
        try context.save()

        let series = StudyService.dailyLearnedSeries(context: context, days: 7)
        #expect(series.count == 7)
        #expect(series.last?.count == 7)
        #expect(series.dropLast().allSatisfy { $0.count == 0 })
    }

    @Test func resetClearsProgressButKeepsWords() throws {
        let context = try makeInMemoryContext()
        let word = makeWord("reset")
        context.insert(word)
        StudyService.grade(word, grade: .known, context: context)
        _ = AchievementEngine.evaluate(context: context)

        StudyService.resetAllProgress(context: context)

        #expect(word.status == .new)
        #expect(word.repetition == 0)
        #expect(word.nextReviewDate == nil)
        #expect(StudyService.allRecords(context: context).isEmpty)
        #expect(AchievementEngine.unlockedKeys(context: context).isEmpty)
        #expect(StudyService.allWords(context: context).count == 1)
    }

    @Test func statusDistributionCoversAllBuckets() throws {
        let context = try makeInMemoryContext()
        for i in 0..<5 { context.insert(makeWord("dist\(i)")) }
        let learned = makeWord("learned")
        context.insert(learned)
        StudyService.grade(learned, grade: .known, context: context)

        let dist = StudyService.statusDistribution(context: context)
        #expect(dist[.new] == 5)
        #expect(dist[.learning] == 1)
        #expect(dist[.mastered] == 0)
    }
}

// MARK: - 成就引擎

@MainActor
struct AchievementEngineTests {
    @Test func firstLessonUnlocksAfterFirstGrade() throws {
        let context = try makeInMemoryContext()
        let word = makeWord("first")
        context.insert(word)
        StudyService.grade(word, grade: .known, context: context)

        let newly = AchievementEngine.evaluate(context: context)
        #expect(newly.contains(.firstLesson))

        // 重复评估不会再次解锁
        let again = AchievementEngine.evaluate(context: context)
        #expect(!again.contains(.firstLesson))
    }

    @Test func perfectQuizRequiresTenQuestionsAllCorrect() throws {
        let context = try makeInMemoryContext()
        let small = AchievementEngine.evaluate(context: context, quizResult: (correct: 5, total: 5))
        #expect(!small.contains(.perfectQuiz))
        #expect(small.contains(.firstQuiz))

        let imperfect = AchievementEngine.evaluate(context: context, quizResult: (correct: 9, total: 10))
        #expect(!imperfect.contains(.perfectQuiz))

        let perfect = AchievementEngine.evaluate(context: context, quizResult: (correct: 10, total: 10))
        #expect(perfect.contains(.perfectQuiz))
    }

    @Test func favoriteAchievementUnlocksAtTen() throws {
        let context = try makeInMemoryContext()
        for i in 0..<10 {
            let word = makeWord("fav\(i)")
            word.isFavorite = true
            context.insert(word)
        }
        try context.save()
        let newly = AchievementEngine.evaluate(context: context)
        #expect(newly.contains(.favorite10))
    }

    @Test func streakAchievementsUnlockTogether() throws {
        let context = try makeInMemoryContext()
        let today = Date().startOfDay
        for offset in 0..<7 {
            let record = DailyStudyRecord(day: today.addingDays(-offset))
            record.newLearned = 1
            context.insert(record)
        }
        try context.save()
        let newly = AchievementEngine.evaluate(context: context)
        #expect(newly.contains(.streak3))
        #expect(newly.contains(.streak7))
        #expect(!newly.contains(.streak30))
    }
}
