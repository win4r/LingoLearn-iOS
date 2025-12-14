//
//  HomeView.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel?
    @State private var navigateToLearning = false
    @State private var navigateToReview = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Daily Progress Card
                    dailyProgressCard

                    // Streak Card
                    streakCard

                    // Words Due for Review Badge
                    if let vm = viewModel, vm.wordsDueForReview > 0 {
                        reviewBadge
                    }

                    // Quick Action Buttons
                    quickActionsSection

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("LingoLearn")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if viewModel == nil {
                    viewModel = HomeViewModel(modelContext: modelContext)
                }
            }
            .refreshable {
                viewModel?.refresh()
            }
            .navigationDestination(isPresented: $navigateToLearning) {
                FlashcardView(mode: .learning)
            }
            .navigationDestination(isPresented: $navigateToReview) {
                FlashcardView(mode: .review)
            }
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("欢迎回来!")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("继续你的学习之旅")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private var dailyProgressCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("今日进度")
                    .font(.headline)

                Spacer()

                if let vm = viewModel, let progress = vm.todayProgress, let goal = vm.userSettings?.dailyGoal {
                    Text("\(progress.wordsLearned + progress.wordsReviewed)/\(goal)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if let vm = viewModel {
                RingProgressView(
                    progress: vm.progressPercentage,
                    lineWidth: 15,
                    gradientColors: [.blue, .purple],
                    size: 140
                )
            }

            if let vm = viewModel, let progress = vm.todayProgress {
                HStack(spacing: 30) {
                    StatItem(title: "已学", value: "\(progress.wordsLearned)", color: .blue)
                    StatItem(title: "已复习", value: "\(progress.wordsReviewed)", color: .purple)
                    StatItem(title: "学习时长", value: "\(Int(progress.totalStudyTime / 60))分", color: .green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var streakCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("连续学习")
                    .font(.headline)

                if let vm = viewModel, let stats = vm.userStats {
                    FlameStreakView(streakCount: stats.currentStreak)

                    Text("最长记录: \(stats.longestStreak)天")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var reviewBadge: some View {
        HStack {
            Image(systemName: "clock.badge.exclamationmark.fill")
                .font(.title2)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("待复习单词")
                    .font(.headline)

                if let vm = viewModel {
                    Text("\(vm.wordsDueForReview)个单词等待复习")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
        .onTapGesture {
            navigateToReview = true
        }
    }

    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            Text("快速操作")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                QuickActionButton(
                    icon: "book.fill",
                    title: "开始学习",
                    subtitle: "学习新单词",
                    color: .blue
                ) {
                    navigateToLearning = true
                }

                QuickActionButton(
                    icon: "arrow.clockwise",
                    title: "快速复习",
                    subtitle: "复习已学单词",
                    color: .purple
                ) {
                    navigateToReview = true
                }

                QuickActionButton(
                    icon: "shuffle",
                    title: "随机测试",
                    subtitle: "测试你的词汇量",
                    color: .green
                ) {
                    // TODO: Navigate to random test
                    print("Navigate to random test")
                }
            }
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Word.self, UserStats.self, DailyProgress.self, UserSettings.self])
}
