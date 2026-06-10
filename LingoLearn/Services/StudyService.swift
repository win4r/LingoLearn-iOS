//
//  StudyService.swift
//  LingoLearn
//
//  学习域核心逻辑：取词队列、SM-2 评分落库、每日记录、连续打卡、重置。
//  词库规模 ~500，全部走内存过滤，避免谓词宏的边角问题。
//

import Foundation
import SwiftData

enum StudyService {
    // MARK: - 查询

    static func allWords(context: ModelContext) -> [Word] {
        (try? context.fetch(FetchDescriptor<Word>())) ?? []
    }

    /// 今日新学批次：未达目标按剩余量取，已达目标仍给一组（支持超额学习）
    static func newWordsBatch(context: ModelContext, dailyGoal: Int, batchLimit: Int = 10) -> [Word] {
        let remaining = dailyGoal - todayRecord(context: context).newLearned
        let size = remaining > 0 ? min(remaining, batchLimit) : batchLimit
        let newWords = allWords(context: context).filter { $0.status == .new }
        return Array(newWords.shuffled().prefix(size))
    }

    /// 到期待复习的单词：nextReviewDate 落在今天 24 点之前（明天 0 点整不算）
    static func dueWords(context: ModelContext, now: Date = Date(), limit: Int = 20) -> [Word] {
        let endOfToday = now.startOfDay.addingDays(1)
        let due = allWords(context: context)
            .filter { word in
                guard let next = word.nextReviewDate else { return false }
                return next < endOfToday && word.status != .new
            }
            .sorted { ($0.nextReviewDate ?? .distantPast) < ($1.nextReviewDate ?? .distantPast) }
        return Array(due.prefix(limit))
    }

    static func dueCount(context: ModelContext, now: Date = Date()) -> Int {
        dueWords(context: context, now: now, limit: .max).count
    }

    /// 按掌握度统计（饼图）
    static func statusDistribution(context: ModelContext) -> [LearningStatus: Int] {
        var dist: [LearningStatus: Int] = [.new: 0, .learning: 0, .mastered: 0]
        for word in allWords(context: context) {
            dist[word.status, default: 0] += 1
        }
        return dist
    }

    // MARK: - 评分落库

    /// 学习卡片作答：跑 SM-2、更新单词状态、累计当日记录。
    static func grade(_ word: Word, grade: ReviewGrade, context: ModelContext, now: Date = Date()) {
        let wasNew = word.firstLearnedDate == nil

        let result = SM2.review(
            state: .init(
                repetition: word.repetition,
                intervalDays: word.intervalDays,
                easeFactor: word.easeFactor
            ),
            quality: grade.quality
        )

        word.repetition = result.state.repetition
        word.intervalDays = result.state.intervalDays
        word.easeFactor = result.state.easeFactor
        word.lastReviewDate = now
        if wasNew { word.firstLearnedDate = now }

        // 间隔 0 = 没记住，10 分钟后再来；否则按自然日推后
        word.nextReviewDate = result.nextIntervalDays == 0
            ? now.addingTimeInterval(10 * 60)
            : now.startOfDay.addingDays(result.nextIntervalDays)

        word.status = SM2.status(for: result.state, hasBeenStudied: true)

        if grade == .forgot {
            word.wrongCount += 1
        } else {
            word.correctCount += 1
        }
        if grade == .favorite {
            word.isFavorite = true
        }

        let record = todayRecord(context: context, now: now)
        if wasNew {
            record.newLearned += 1
        } else {
            record.reviewed += 1
        }

        try? context.save()
    }

    /// 练习结果计入当日记录
    static func recordQuiz(correct: Int, total: Int, context: ModelContext, now: Date = Date()) {
        let record = todayRecord(context: context, now: now)
        record.quizAnswered += total
        record.quizCorrect += correct
        try? context.save()
    }

    // MARK: - 每日记录 / 打卡

    static func allRecords(context: ModelContext) -> [DailyStudyRecord] {
        (try? context.fetch(FetchDescriptor<DailyStudyRecord>())) ?? []
    }

    /// 取（或建）今天的记录
    static func todayRecord(context: ModelContext, now: Date = Date()) -> DailyStudyRecord {
        let today = now.startOfDay
        if let existing = allRecords(context: context).first(where: { $0.day == today }) {
            return existing
        }
        let record = DailyStudyRecord(day: today)
        context.insert(record)
        return record
    }

    /// 连续打卡天数：从今天（或昨天）往回数有学习活动的天数
    static func streak(context: ModelContext, now: Date = Date()) -> Int {
        let activeDays = Set(
            allRecords(context: context)
                .filter { $0.totalActivity > 0 }
                .map { $0.day.startOfDay }
        )
        guard !activeDays.isEmpty else { return 0 }

        let today = now.startOfDay
        var cursor = activeDays.contains(today) ? today : today.addingDays(-1)
        var count = 0
        while activeDays.contains(cursor) {
            count += 1
            cursor = cursor.addingDays(-1)
        }
        return count
    }

    /// 近 N 天每日新学数（折线图，缺日补 0，含今天）
    static func dailyLearnedSeries(context: ModelContext, days: Int, now: Date = Date()) -> [(day: Date, count: Int)] {
        let byDay = Dictionary(
            uniqueKeysWithValues: allRecords(context: context).map { ($0.day.startOfDay, $0.newLearned) }
        )
        let today = now.startOfDay
        return (0..<days).reversed().map { offset in
            let day = today.addingDays(-offset)
            return (day, byDay[day] ?? 0)
        }
    }

    /// 热力图数据：近 N 天每日总活动量
    static func activitySeries(context: ModelContext, days: Int, now: Date = Date()) -> [Date: Int] {
        var result: [Date: Int] = [:]
        let earliest = now.startOfDay.addingDays(-(days - 1))
        for record in allRecords(context: context) where record.day >= earliest {
            result[record.day.startOfDay] = record.totalActivity
        }
        return result
    }

    // MARK: - 重置

    /// 清空全部学习进度（保留词库本身）
    static func resetAllProgress(context: ModelContext) {
        for word in allWords(context: context) {
            word.resetLearningState()
        }
        for record in allRecords(context: context) {
            context.delete(record)
        }
        let achievements = (try? context.fetch(FetchDescriptor<Achievement>())) ?? []
        for achievement in achievements {
            context.delete(achievement)
        }
        try? context.save()
    }
}
