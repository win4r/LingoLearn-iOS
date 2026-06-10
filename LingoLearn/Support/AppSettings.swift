//
//  AppSettings.swift
//  LingoLearn
//

import SwiftUI

/// UserDefaults 键，@AppStorage 与服务层共用。
enum SettingsKeys {
    static let dailyGoal = "settings.dailyGoal"
    static let reminderEnabled = "settings.reminderEnabled"
    static let reminderMinutes = "settings.reminderMinutes" // 距 0 点的分钟数
    static let soundEnabled = "settings.soundEnabled"
    static let hapticsEnabled = "settings.hapticsEnabled"
    static let autoPlayPronunciation = "settings.autoPlayPronunciation"
    static let appearance = "settings.appearance"
    static let seededVersion = "data.seededVersion"

    /// 注册默认值（App 启动时调用一次）
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            dailyGoal: 20,
            reminderEnabled: false,
            reminderMinutes: 20 * 60, // 默认 20:00
            soundEnabled: true,
            hapticsEnabled: true,
            autoPlayPronunciation: true,
            appearance: AppearanceMode.system.rawValue,
        ])
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "跟随系统"
        case .light: "浅色"
        case .dark: "深色"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
