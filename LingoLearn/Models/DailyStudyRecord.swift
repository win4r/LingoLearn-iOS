//
//  DailyStudyRecord.swift
//  LingoLearn
//

import Foundation
import SwiftData

/// 按天聚合的学习记录，驱动打卡、折线图与热力图。
@Model
final class DailyStudyRecord {
    /// 当天 0 点（startOfDay），同一天只有一条记录
    var day: Date = Date()
    /// 当天首次学会的新词数
    var newLearned: Int = 0
    /// 当天复习的卡片数
    var reviewed: Int = 0
    /// 当天练习答题数
    var quizAnswered: Int = 0
    /// 当天练习答对数
    var quizCorrect: Int = 0

    init(day: Date) {
        self.day = day
    }

    /// 当天总活动量（热力图强度）
    var totalActivity: Int {
        newLearned + reviewed + quizAnswered
    }
}
