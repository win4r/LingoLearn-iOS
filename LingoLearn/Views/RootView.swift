//
//  RootView.swift
//  LingoLearn
//
//  根视图：词库播种门控（加载/失败/就绪）+ 主 Tab。
//

import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKeys.appearance) private var appearanceRaw = AppearanceMode.system.rawValue

    enum SeedState {
        case loading
        case ready
        case failed(String)
    }

    @State private var seedState: SeedState = .loading

    var body: some View {
        Group {
            switch seedState {
            case .loading:
                LoadingStateView(text: "正在准备词库…")
            case .failed(let message):
                ErrorStateView(
                    title: "词库加载失败",
                    message: message,
                    retryTitle: "重试",
                    onRetry: { seed() }
                )
            case .ready:
                MainTabView()
            }
        }
        .preferredColorScheme((AppearanceMode(rawValue: appearanceRaw) ?? .system).colorScheme)
        .tint(.brandPrimary)
        .task { seed() }
    }

    private func seed() {
        seedState = .loading
        do {
            try WordSeeder.seedIfNeeded(context: modelContext)
            seedState = .ready
        } catch {
            seedState = .failed(error.localizedDescription)
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("首页", systemImage: "house.fill") }
            PracticeSetupView()
                .tabItem { Label("练习", systemImage: "square.and.pencil") }
            StatsView()
                .tabItem { Label("进度", systemImage: "chart.xyaxis.line") }
            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape.fill") }
        }
    }
}
