//
//  SettingsView.swift
//  LingoLearn
//

import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage(SettingsKeys.dailyGoal) private var dailyGoal = 20
    @AppStorage(SettingsKeys.reminderEnabled) private var reminderEnabled = false
    @AppStorage(SettingsKeys.reminderMinutes) private var reminderMinutes = 20 * 60
    @AppStorage(SettingsKeys.soundEnabled) private var soundEnabled = true
    @AppStorage(SettingsKeys.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsKeys.autoPlayPronunciation) private var autoPlay = true
    @AppStorage(SettingsKeys.appearance) private var appearanceRaw = AppearanceMode.system.rawValue

    @State private var showResetDialog = false
    @State private var showResetFinalAlert = false
    @State private var showPermissionAlert = false
    @State private var resetDone = false
    @State private var cet4Count = 0
    @State private var cet6Count = 0

    private var goalBinding: Binding<Double> {
        Binding(
            get: { Double(dailyGoal) },
            set: { dailyGoal = Int($0.rounded()) }
        )
    }

    /// 提醒时间 ←→ 距 0 点分钟数
    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                Date().startOfDay.addingTimeInterval(TimeInterval(reminderMinutes * 60))
            },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                reminderMinutes = (comps.hour ?? 20) * 60 + (comps.minute ?? 0)
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                goalSection
                reminderSection
                feedbackSection
                appearanceSection
                lexiconSection
                dangerSection
                aboutSection
            }
            .navigationTitle("设置")
        }
        .onAppear { refreshCounts() }
        .onChange(of: reminderMinutes) {
            guard reminderEnabled else { return }
            Task { await NotificationManager.scheduleDaily(minutesFromMidnight: reminderMinutes) }
        }
        .alert("通知权限未开启", isPresented: $showPermissionAlert) {
            Button("去设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("请在系统设置中允许 LingoLearn 发送通知，才能收到每日学习提醒。")
        }
        .alert("确定要重置全部学习进度吗？", isPresented: $showResetFinalAlert) {
            Button("确认重置", role: .destructive) { performReset() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("所有学习记录、打卡、收藏与成就将被清空，且无法恢复。")
        }
        .sensoryFeedback(.success, trigger: resetDone)
    }

    // MARK: - 分区

    private var goalSection: some View {
        Section("学习目标") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("每日目标", systemImage: "target")
                    Spacer()
                    Text("\(dailyGoal) 个 / 天")
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(Color.brandPrimary)
                }
                Slider(value: goalBinding, in: 10...100, step: 5) {
                    Text("每日目标")
                } minimumValueLabel: {
                    Text("10").font(.caption2).foregroundStyle(.secondary)
                } maximumValueLabel: {
                    Text("100").font(.caption2).foregroundStyle(.secondary)
                } onEditingChanged: { editing in
                    if !editing { Haptics.tap() }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var reminderSection: some View {
        Section("学习提醒") {
            Toggle(isOn: $reminderEnabled) {
                Label("每日提醒", systemImage: "bell.badge.fill")
            }
            .onChange(of: reminderEnabled) {
                Haptics.tap()
                if reminderEnabled {
                    Task {
                        if await NotificationManager.requestAuthorization() {
                            await NotificationManager.scheduleDaily(minutesFromMidnight: reminderMinutes)
                        } else {
                            reminderEnabled = false
                            showPermissionAlert = true
                        }
                    }
                } else {
                    NotificationManager.cancelDaily()
                }
            }

            if reminderEnabled {
                DatePicker(
                    selection: reminderTimeBinding,
                    displayedComponents: .hourAndMinute
                ) {
                    Label("提醒时间", systemImage: "clock.fill")
                }
            }
        }
    }

    private var feedbackSection: some View {
        Section("音效与反馈") {
            Toggle(isOn: $soundEnabled) {
                Label("音效", systemImage: "speaker.wave.2.fill")
            }
            .onChange(of: soundEnabled) { Haptics.tap() }

            Toggle(isOn: $hapticsEnabled) {
                Label("震动反馈", systemImage: "iphone.radiowaves.left.and.right")
            }

            Toggle(isOn: $autoPlay) {
                Label("自动播放发音", systemImage: "play.circle.fill")
            }
            .onChange(of: autoPlay) { Haptics.tap() }
        }
    }

    private var appearanceSection: some View {
        Section("外观") {
            Picker(selection: $appearanceRaw) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.displayName).tag(mode.rawValue)
                }
            } label: {
                Label("外观模式", systemImage: "circle.lefthalf.filled")
            }
            .onChange(of: appearanceRaw) { Haptics.tap() }
        }
    }

    private var lexiconSection: some View {
        Section("词库") {
            LabeledContent {
                Text("\(cet4Count) 词").foregroundStyle(.secondary)
            } label: {
                Label("CET-4 核心词汇", systemImage: "4.circle.fill")
            }
            LabeledContent {
                Text("\(cet6Count) 词").foregroundStyle(.secondary)
            } label: {
                Label("CET-6 进阶词汇", systemImage: "6.circle.fill")
            }
        }
    }

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                Haptics.warning()
                showResetDialog = true
            } label: {
                Label("重置学习进度", systemImage: "trash.fill")
            }
            .confirmationDialog(
                "重置后所有学习数据将被清空",
                isPresented: $showResetDialog,
                titleVisibility: .visible
            ) {
                Button("我要重置", role: .destructive) {
                    showResetFinalAlert = true
                }
                Button("取消", role: .cancel) {}
            }
        } footer: {
            Text("仅清空学习记录与成就，预置词库会保留。")
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("版本") {
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            }
        } footer: {
            Text("LingoLearn · 基于 SM-2 间隔重复算法的背单词应用")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
    }

    private func refreshCounts() {
        let words = StudyService.allWords(context: modelContext)
        cet4Count = words.filter { $0.category == .cet4 }.count
        cet6Count = words.filter { $0.category == .cet6 }.count
    }

    private func performReset() {
        StudyService.resetAllProgress(context: modelContext)
        resetDone.toggle()
    }
}
