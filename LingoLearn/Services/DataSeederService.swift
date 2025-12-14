import Foundation
import SwiftData

struct WordData: Codable {
    let english: String
    let chinese: String
    let phonetic: String
    let partOfSpeech: String
    let exampleSentence: String
    let exampleTranslation: String
    let difficulty: Int
}

struct WordsJSON: Codable {
    let category: String
    let words: [WordData]
}

final class DataSeederService {
    private static let hasSeededKey = "hasSeededWords"

    static func seedDataIfNeeded(modelContext: ModelContext) {
        // Check if data has already been seeded
        let hasSeeded = UserDefaults.standard.bool(forKey: hasSeededKey)
        guard !hasSeeded else {
            print("Data already seeded, skipping...")
            return
        }

        print("Starting data seeding...")

        // Seed CET-4 words
        seedWords(from: "cet4_words", category: .cet4, modelContext: modelContext)

        // Seed CET-6 words
        seedWords(from: "cet6_words", category: .cet6, modelContext: modelContext)

        // Create default UserStats
        let userStats = UserStats()
        modelContext.insert(userStats)

        // Create default UserSettings
        let userSettings = UserSettings()
        modelContext.insert(userSettings)

        // Save context
        do {
            try modelContext.save()
            UserDefaults.standard.set(true, forKey: hasSeededKey)
            print("Data seeding completed successfully!")
        } catch {
            print("Failed to save seeded data: \(error)")
        }
    }

    private static func seedWords(from filename: String, category: WordCategory, modelContext: ModelContext) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("Could not find \(filename).json")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let wordsJSON = try decoder.decode(WordsJSON.self, from: data)

            for wordData in wordsJSON.words {
                let word = Word(
                    english: wordData.english,
                    chinese: wordData.chinese,
                    phonetic: wordData.phonetic,
                    partOfSpeech: wordData.partOfSpeech,
                    exampleSentence: wordData.exampleSentence,
                    exampleTranslation: wordData.exampleTranslation,
                    category: category,
                    difficulty: wordData.difficulty
                )
                modelContext.insert(word)
            }

            print("Seeded \(wordsJSON.words.count) words from \(filename)")
        } catch {
            print("Error seeding words from \(filename): \(error)")
        }
    }

    // Reset seeding flag (useful for development/testing)
    static func resetSeedingFlag() {
        UserDefaults.standard.removeObject(forKey: hasSeededKey)
    }
}
