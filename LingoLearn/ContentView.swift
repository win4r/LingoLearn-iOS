//
//  ContentView.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(0)

            FlashcardView(mode: .learning)
                .tabItem {
                    Label("学习", systemImage: "book.fill")
                }
                .tag(1)

            PracticeMenuView()
                .tabItem {
                    Label("练习", systemImage: "gamecontroller.fill")
                }
                .tag(2)

            LearningProgressView()
                .tabItem {
                    Label("进度", systemImage: "chart.bar.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(.primaryBlue)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Word.self, StudySession.self, DailyProgress.self, UserStats.self, UserSettings.self])
}
