//
//  Achievement.swift
//  LingoLearn
//

import Foundation
import SwiftData

/// 已解锁的成就（仅在解锁时插入一条记录）。
@Model
final class Achievement {
    var key: String = ""
    var unlockedAt: Date = Date()

    init(key: String, unlockedAt: Date = Date()) {
        self.key = key
        self.unlockedAt = unlockedAt
    }
}

/// 全部成就的静态定义。
enum AchievementKind: String, CaseIterable, Identifiable {
    case firstLesson
    case firstQuiz
    case streak3
    case streak7
    case streak30
    case learned100
    case learned500
    case mastered100
    case favorite10
    case perfectQuiz

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstLesson: "初次见面"
        case .firstQuiz: "小试牛刀"
        case .streak3: "渐入佳境"
        case .streak7: "七日之约"
        case .streak30: "月度坚持"
        case .learned100: "百词斩"
        case .learned500: "词汇大师"
        case .mastered100: "融会贯通"
        case .favorite10: "收藏家"
        case .perfectQuiz: "完美主义"
        }
    }

    var subtitle: String {
        switch self {
        case .firstLesson: "完成首次单词学习"
        case .firstQuiz: "完成首次练习测试"
        case .streak3: "连续打卡 3 天"
        case .streak7: "连续打卡 7 天"
        case .streak30: "连续打卡 30 天"
        case .learned100: "累计学习 100 个单词"
        case .learned500: "累计学习 500 个单词"
        case .mastered100: "掌握 100 个单词"
        case .favorite10: "收藏 10 个单词"
        case .perfectQuiz: "单次练习（≥10题）全对"
        }
    }

    var icon: String {
        switch self {
        case .firstLesson: "sparkles"
        case .firstQuiz: "checkmark.seal.fill"
        case .streak3: "flame"
        case .streak7: "flame.fill"
        case .streak30: "calendar.badge.checkmark"
        case .learned100: "book.fill"
        case .learned500: "books.vertical.fill"
        case .mastered100: "brain.head.profile"
        case .favorite10: "star.fill"
        case .perfectQuiz: "crown.fill"
        }
    }
}
