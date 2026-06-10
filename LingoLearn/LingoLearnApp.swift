//
//  LingoLearnApp.swift
//  LingoLearn
//

import SwiftData
import SwiftUI

@main
struct LingoLearnApp: App {
    private let containerResult: Result<ModelContainer, Error>

    init() {
        SettingsKeys.registerDefaults()
        do {
            let container = try ModelContainer(
                for: Word.self, DailyStudyRecord.self, Achievement.self
            )
            containerResult = .success(container)
        } catch {
            containerResult = .failure(error)
        }
    }

    var body: some Scene {
        WindowGroup {
            switch containerResult {
            case .success(let container):
                RootView()
                    .modelContainer(container)
            case .failure(let error):
                ErrorStateView(
                    title: "数据初始化失败",
                    message: "本地数据库无法打开：\(error.localizedDescription)\n请尝试重新安装应用。",
                    retryTitle: nil,
                    onRetry: nil
                )
            }
        }
    }
}
