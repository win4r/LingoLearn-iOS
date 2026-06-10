//
//  HomeView.swift
//  LingoLearn
//

import SwiftData
import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKeys.dailyGoal) private var dailyGoal = 20

    @State private var todayLearned = 0
    @State private var todayReviewed = 0
    @State private var todayQuizzed = 0
    @State private var streak = 0
    @State private var dueCount = 0
    @State private var activeSession: SessionKind?

    enum SessionKind: String, Identifiable {
        case learn, review, randomQuiz
        var id: String { rawValue }
    }

    private var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1, Double(todayLearned) / Double(dailyGoal))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    progressCard
                    quickActions
                    todayStats
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("LingoLearn")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 5) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(streak > 0 ? .orange : .gray)
                        Text("\(streak) 天")
                            .font(.subheadline.bold())
                            .foregroundStyle(streak > 0 ? .orange : .secondary)
                    }
                    .accessibilityLabel("连续打卡 \(streak) 天")
                }
            }
        }
        .onAppear { refresh() }
        .fullScreenCover(item: $activeSession, onDismiss: { refresh() }) { kind in
            switch kind {
            case .learn:
                LearnSessionView(mode: .newWords)
            case .review:
                LearnSessionView(mode: .review)
            case .randomQuiz:
                QuizRunView(config: .random)
            }
        }
    }

    // MARK: - 进度卡片

    private var progressCard: some View {
        VStack(spacing: 16) {
            ZStack {
                ProgressRing(progress: progress)
                    .frame(width: 170, height: 170)
                VStack(spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(todayLearned)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(LinearGradient.brand)
                            .contentTransition(.numericText())
                        Text("/ \(dailyGoal)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Text("今日已学")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)

            if todayLearned >= dailyGoal {
                Label("今日目标已完成，太棒了！", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.brandSecondary)
            } else {
                Text("距离今日目标还差 \(dailyGoal - todayLearned) 个单词")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if dueCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "clock.badge.exclamationmark")
                    Text("有 \(dueCount) 个单词待复习")
                }
                .font(.footnote.bold())
                .foregroundStyle(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(.orange.opacity(0.12)))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .cardSurface()
        .animation(.spring(duration: 0.6), value: todayLearned)
    }

    // MARK: - 快捷入口

    private var quickActions: some View {
        VStack(spacing: 12) {
            Button {
                Haptics.medium()
                activeSession = .learn
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("开始学习")
                            .font(.title3.bold())
                        Text(todayLearned >= dailyGoal ? "目标已达成，可继续超额学习" : "学习新单词，完成今日目标")
                            .font(.caption)
                            .opacity(0.85)
                    }
                    Spacer()
                    Image(systemName: "book.fill")
                        .font(.system(size: 34))
                        .opacity(0.9)
                }
                .foregroundStyle(.white)
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(LinearGradient.brand)
                        .shadow(color: Color.brandPrimary.opacity(0.35), radius: 10, y: 5)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("开始学习")

            HStack(spacing: 12) {
                QuickActionCard(
                    title: "快速复习",
                    icon: "arrow.clockwise.circle.fill",
                    color: .brandSecondary,
                    badge: dueCount
                ) {
                    activeSession = .review
                }
                QuickActionCard(
                    title: "随机测试",
                    icon: "dice.fill",
                    color: .indigo,
                    badge: 0
                ) {
                    activeSession = .randomQuiz
                }
            }
        }
    }

    // MARK: - 今日小结

    private var todayStats: some View {
        HStack(spacing: 12) {
            StatChip(value: todayLearned, label: "新学", icon: "plus.circle.fill", color: .brandPrimary)
            StatChip(value: todayReviewed, label: "复习", icon: "arrow.clockwise", color: .brandSecondary)
            StatChip(value: todayQuizzed, label: "练习", icon: "pencil.circle.fill", color: .indigo)
        }
    }

    private func refresh() {
        let record = StudyService.todayRecord(context: modelContext)
        todayLearned = record.newLearned
        todayReviewed = record.reviewed
        todayQuizzed = record.quizAnswered
        streak = StudyService.streak(context: modelContext)
        dueCount = StudyService.dueCount(context: modelContext)
    }
}

// MARK: - 组件

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 16

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.brandPrimary.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(
                    AngularGradient(
                        colors: [.brandPrimary, .brandSecondary, .brandPrimary],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.8), value: progress)
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let badge: Int
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .cardSurface()
            .overlay(alignment: .topTrailing) {
                if badge > 0 {
                    Text("\(min(badge, 99))")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(.red))
                        .offset(x: -8, y: 8)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct StatChip: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text("\(value)")
                    .font(.title3.bold().monospacedDigit())
            }
            .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .cardSurface(cornerRadius: 14)
    }
}
