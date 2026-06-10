//
//  QuizEngine.swift
//  LingoLearn
//
//  练习测试出题与判分。
//

import Foundation

enum QuizType: String, CaseIterable, Identifiable {
    case choice
    case spelling
    case listening

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .choice: "选择题"
        case .spelling: "填空题"
        case .listening: "听力题"
        }
    }

    var icon: String {
        switch self {
        case .choice: "list.bullet.circle.fill"
        case .spelling: "keyboard.fill"
        case .listening: "headphones.circle.fill"
        }
    }

    var detail: String {
        switch self {
        case .choice: "看单词，选中文释义"
        case .spelling: "看释义，拼写英文单词"
        case .listening: "听发音，选正确单词"
        }
    }
}

struct QuizQuestion: Identifiable {
    let id = UUID()
    let type: QuizType
    let word: Word
    /// 选择/听力题的四个选项文案；填空题为空
    let options: [String]
    /// 正确选项下标（填空题为 -1）
    let correctIndex: Int
}

struct QuizAnswerRecord: Identifiable {
    let id = UUID()
    let question: QuizQuestion
    /// 用户作答文案；nil = 超时未答
    let userAnswer: String?
    let isCorrect: Bool
}

enum QuizEngine {
    /// 生成一组题目。
    /// - Parameters:
    ///   - type: 指定题型；nil = 每题随机（随机测试）
    ///   - pool: 优先出题的词（已学优先），不足时由 allWords 补齐
    static func makeQuestions(
        type: QuizType?,
        count: Int,
        allWords: [Word]
    ) -> [QuizQuestion] {
        guard allWords.count >= 4, count > 0 else { return [] }

        let studied = allWords.filter { $0.status != .new }.shuffled()
        let fresh = allWords.filter { $0.status == .new }.shuffled()
        let targets = Array((studied + fresh).prefix(count))

        return targets.map { word in
            let questionType = type ?? QuizType.allCases.randomElement()!
            return makeQuestion(type: questionType, word: word, allWords: allWords)
        }
    }

    static func makeQuestion(type: QuizType, word: Word, allWords: [Word]) -> QuizQuestion {
        switch type {
        case .spelling:
            return QuizQuestion(type: .spelling, word: word, options: [], correctIndex: -1)

        case .choice:
            let correct = word.meaning
            let distractors = distinctDistractors(
                from: allWords, excluding: word, keyPath: \.meaning, count: 3
            )
            let (options, index) = shuffledOptions(correct: correct, distractors: distractors)
            return QuizQuestion(type: .choice, word: word, options: options, correctIndex: index)

        case .listening:
            let correct = word.english
            let distractors = distinctDistractors(
                from: allWords, excluding: word, keyPath: \.english, count: 3
            )
            let (options, index) = shuffledOptions(correct: correct, distractors: distractors)
            return QuizQuestion(type: .listening, word: word, options: options, correctIndex: index)
        }
    }

    /// 从词库随机取干扰项，保证与正确答案及彼此都不重复
    private static func distinctDistractors(
        from words: [Word],
        excluding target: Word,
        keyPath: KeyPath<Word, String>,
        count: Int
    ) -> [String] {
        var seen: Set<String> = [target[keyPath: keyPath]]
        var result: [String] = []
        for word in words.shuffled() {
            let value = word[keyPath: keyPath]
            guard !seen.contains(value) else { continue }
            seen.insert(value)
            result.append(value)
            if result.count == count { break }
        }
        return result
    }

    private static func shuffledOptions(correct: String, distractors: [String]) -> ([String], Int) {
        var options = distractors
        let index = Int.random(in: 0...options.count)
        options.insert(correct, at: index)
        return (options, index)
    }

    /// 填空题判分：大小写不敏感、忽略首尾空白
    static func checkSpelling(input: String, answer: String) -> Bool {
        input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            == answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
