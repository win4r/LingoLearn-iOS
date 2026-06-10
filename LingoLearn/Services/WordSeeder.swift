//
//  WordSeeder.swift
//  LingoLearn
//
//  首次启动时从 Bundle JSON 导入预置词库。
//

import Foundation
import SwiftData

struct SeedWord: Decodable {
    let en: String
    let ph: String
    let zh: String
    let ex: String
    let tr: String
}

enum WordSeederError: LocalizedError {
    case resourceMissing(String)

    var errorDescription: String? {
        switch self {
        case .resourceMissing(let name):
            "缺少词库文件 \(name).json"
        }
    }
}

enum WordSeeder {
    /// 词库版本号；新增词库文件时 +1 可触发增量补种
    static let currentVersion = 1

    /// 资源文件名 → 分类
    static let resources: [(name: String, category: WordCategory)] = [
        ("words-cet4-1", .cet4),
        ("words-cet4-2", .cet4),
        ("words-cet6-1", .cet6),
        ("words-cet6-2", .cet6),
    ]

    /// 从指定 Bundle 解码全部预置词（测试也走这条路径）
    static func loadSeedWords(bundle: Bundle = .main) throws -> [(SeedWord, WordCategory)] {
        var result: [(SeedWord, WordCategory)] = []
        for (name, category) in resources {
            guard let url = bundle.url(forResource: name, withExtension: "json") else {
                throw WordSeederError.resourceMissing(name)
            }
            let data = try Data(contentsOf: url)
            let words = try JSONDecoder().decode([SeedWord].self, from: data)
            result.append(contentsOf: words.map { ($0, category) })
        }
        return result
    }

    /// 幂等播种：已播种过当前版本则跳过；按 english 去重。
    static func seedIfNeeded(context: ModelContext, bundle: Bundle = .main) throws {
        let seeded = UserDefaults.standard.integer(forKey: SettingsKeys.seededVersion)
        guard seeded < currentVersion else { return }

        let existing = try context.fetch(FetchDescriptor<Word>())
        var known = Set(existing.map { $0.english.lowercased() })

        for (seed, category) in try loadSeedWords(bundle: bundle) {
            let key = seed.en.lowercased()
            guard !known.contains(key) else { continue }
            known.insert(key)
            context.insert(Word(
                english: seed.en,
                phonetic: seed.ph,
                meaning: seed.zh,
                example: seed.ex,
                exampleTranslation: seed.tr,
                category: category
            ))
        }

        try context.save()
        UserDefaults.standard.set(currentVersion, forKey: SettingsKeys.seededVersion)
    }
}
