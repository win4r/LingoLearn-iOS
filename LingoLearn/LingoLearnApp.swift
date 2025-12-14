//
//  LingoLearnApp.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI
import SwiftData

@main
struct LingoLearnApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Word.self,
            StudySession.self,
            DailyProgress.self,
            UserStats.self,
            UserSettings.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
                .onAppear {
                    // Seed data on first launch
                    DataSeederService.seedDataIfNeeded(modelContext: sharedModelContainer.mainContext)
                }
        }
    }
}
