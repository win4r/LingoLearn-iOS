//
//  SettingsView.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SettingsViewModel?
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    settingsForm(viewModel: viewModel)
                } else {
                    ProgressView("加载中...")
                }
            }
            .navigationTitle("设置")
            .onAppear {
                if viewModel == nil {
                    viewModel = SettingsViewModel(modelContext: modelContext)
                    viewModel?.loadSettings()
                }
            }
            .alert("重置学习进度", isPresented: $showResetConfirmation) {
                Button("取消", role: .cancel) { }
                Button("重置", role: .destructive) {
                    viewModel?.resetProgress()
                }
            } message: {
                Text("确定要重置所有学习进度吗？此操作无法撤销。")
            }
        }
    }

    @ViewBuilder
    private func settingsForm(viewModel: SettingsViewModel) -> some View {
        Form {
            // Learning Goal Section
            Section {
                DailyGoalSlider(
                    value: Binding(
                        get: { viewModel.dailyGoal },
                        set: { viewModel.dailyGoal = $0 }
                    ),
                    range: 10...100,
                    step: 5
                )
            } header: {
                Text("学习目标")
            } footer: {
                Text("每天学习 \(viewModel.dailyGoal) 个单词")
            }

            // Reminder Section
            Section {
                Toggle("开启每日提醒", isOn: Binding(
                    get: { viewModel.reminderEnabled },
                    set: { newValue in
                        viewModel.reminderEnabled = newValue
                        Task {
                            await viewModel.handleReminderToggle(newValue)
                        }
                    }
                ))

                if viewModel.reminderEnabled {
                    ReminderPicker(time: Binding(
                        get: { viewModel.reminderTime },
                        set: { newValue in
                            viewModel.reminderTime = newValue
                            Task {
                                await viewModel.scheduleReminder()
                            }
                        }
                    ))
                }
            } header: {
                Text("提醒设置")
            }

            // Feedback Section
            Section {
                Toggle("声音效果", isOn: Binding(
                    get: { viewModel.soundEnabled },
                    set: { viewModel.soundEnabled = $0 }
                ))
                Toggle("触觉反馈", isOn: Binding(
                    get: { viewModel.hapticsEnabled },
                    set: { viewModel.hapticsEnabled = $0 }
                ))
            } header: {
                Text("反馈设置")
            }

            // Pronunciation Section
            Section {
                Toggle("自动播放发音", isOn: Binding(
                    get: { viewModel.autoPlayPronunciation },
                    set: { viewModel.autoPlayPronunciation = $0 }
                ))
            } header: {
                Text("发音设置")
            } footer: {
                Text("学习新单词时自动播放发音")
            }

            // Appearance Section
            Section {
                Picker("外观模式", selection: Binding(
                    get: { viewModel.appearanceMode },
                    set: { viewModel.appearanceMode = $0 }
                )) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("外观")
            }

            // Data Section
            Section {
                Button(role: .destructive, action: {
                    showResetConfirmation = true
                }) {
                    Label("重置学习进度", systemImage: "exclamationmark.triangle")
                }
            } header: {
                Text("数据")
            } footer: {
                Text("此操作将删除所有学习记录，但保留已学单词")
            }

            // App Info Section
            Section {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }

                Link(destination: URL(string: "https://example.com/privacy")!) {
                    HStack {
                        Text("隐私政策")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Link(destination: URL(string: "https://example.com/terms")!) {
                    HStack {
                        Text("服务条款")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("关于")
            }
        }
    }
}

// Extension to add display name for AppearanceMode
extension AppearanceMode {
    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserSettings.self, DailyProgress.self, UserStats.self])
}
