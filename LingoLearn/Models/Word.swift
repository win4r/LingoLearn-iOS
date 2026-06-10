//
//  Word.swift
//  LingoLearn
//

import Foundation
import SwiftData

enum WordCategory: String, CaseIterable, Identifiable, Codable {
    case cet4 = "CET4"
    case cet6 = "CET6"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

enum LearningStatus: String, CaseIterable, Identifiable {
    case new
    case learning
    case mastered

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .new: "新学"
        case .learning: "学习中"
        case .mastered: "已掌握"
        }
    }
}

@Model
final class Word {
    var english: String = ""
    var phonetic: String = ""
    var meaning: String = ""
    var example: String = ""
    var exampleTranslation: String = ""
    var categoryRaw: String = WordCategory.cet4.rawValue

    // 学习状态（SM-2）
    var statusRaw: String = LearningStatus.new.rawValue
    var isFavorite: Bool = false
    var repetition: Int = 0
    var intervalDays: Int = 0
    var easeFactor: Double = 2.5
    var nextReviewDate: Date?
    var lastReviewDate: Date?
    var firstLearnedDate: Date?
    var correctCount: Int = 0
    var wrongCount: Int = 0

    init(
        english: String,
        phonetic: String,
        meaning: String,
        example: String,
        exampleTranslation: String,
        category: WordCategory
    ) {
        self.english = english
        self.phonetic = phonetic
        self.meaning = meaning
        self.example = example
        self.exampleTranslation = exampleTranslation
        self.categoryRaw = category.rawValue
    }

    var category: WordCategory {
        get { WordCategory(rawValue: categoryRaw) ?? .cet4 }
        set { categoryRaw = newValue.rawValue }
    }

    var status: LearningStatus {
        get { LearningStatus(rawValue: statusRaw) ?? .new }
        set { statusRaw = newValue.rawValue }
    }

    /// 清空学习状态（重置进度时使用）
    func resetLearningState() {
        statusRaw = LearningStatus.new.rawValue
        isFavorite = false
        repetition = 0
        intervalDays = 0
        easeFactor = 2.5
        nextReviewDate = nil
        lastReviewDate = nil
        firstLearnedDate = nil
        correctCount = 0
        wrongCount = 0
    }
}
