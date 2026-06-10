//
//  SM2.swift
//  LingoLearn
//
//  SuperMemo SM-2 间隔重复算法（纯函数，便于单测）。
//

import Foundation

/// 学习卡片上的一次作答评级
enum ReviewGrade {
    /// 左滑「不认识」
    case forgot
    /// 右滑「认识」
    case known
    /// 上滑「收藏」（按认识处理，质量略低于完全认识）
    case favorite

    /// 映射到 SM-2 的 0–5 质量分
    var quality: Int {
        switch self {
        case .forgot: 1
        case .known: 5
        case .favorite: 4
        }
    }
}

enum SM2 {
    struct State: Equatable {
        var repetition: Int
        var intervalDays: Int
        var easeFactor: Double

        static let initial = State(repetition: 0, intervalDays: 0, easeFactor: 2.5)
    }

    struct Result: Equatable {
        var state: State
        /// 距今天数；0 表示需要当天再次复习
        var nextIntervalDays: Int
    }

    /// 标准 SM-2：
    /// - q >= 3：rep1 → 1 天，rep2 → 6 天，之后 interval × EF
    /// - q < 3：重置重复计数，当天稍后重试
    /// - EF' = EF + (0.1 - (5-q) * (0.08 + (5-q) * 0.02))，下限 1.3
    static func review(state: State, quality: Int) -> Result {
        let q = max(0, min(5, quality))
        var s = state

        let delta = 0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02)
        s.easeFactor = max(1.3, s.easeFactor + delta)

        if q >= 3 {
            switch s.repetition {
            case 0: s.intervalDays = 1
            case 1: s.intervalDays = 6
            default: s.intervalDays = Int((Double(s.intervalDays) * s.easeFactor).rounded())
            }
            s.repetition += 1
        } else {
            s.repetition = 0
            s.intervalDays = 0
        }

        return Result(state: s, nextIntervalDays: s.intervalDays)
    }

    /// 由 SM-2 状态推导掌握程度
    static func status(for state: State, hasBeenStudied: Bool) -> LearningStatus {
        guard hasBeenStudied else { return .new }
        if state.repetition >= 4 && state.intervalDays >= 21 {
            return .mastered
        }
        return .learning
    }
}
