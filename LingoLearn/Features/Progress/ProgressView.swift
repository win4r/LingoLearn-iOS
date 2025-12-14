//
//  ProgressView.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI
import SwiftData

struct LearningProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ProgressViewModel?
    @State private var selectedPeriod: TimePeriod = .week

    enum TimePeriod: String, CaseIterable {
        case week = "7天"
        case month = "30天"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Period Selector
                    Picker("Time Period", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedPeriod) { _, newValue in
                        viewModel?.updatePeriod(newValue == .week ? 7 : 30)
                    }

                    // Stats Cards
                    statsCardsSection

                    // Line Chart
                    lineChartSection

                    // Calendar Heatmap
                    calendarHeatmapSection

                    // Mastery Distribution
                    masteryDistributionSection

                    // Achievement Wall
                    achievementWallSection
                }
                .padding(.vertical)
            }
            .navigationTitle("学习进度")
            .onAppear {
                if viewModel == nil {
                    viewModel = ProgressViewModel(modelContext: modelContext)
                }
                viewModel?.loadData()
            }
        }
    }

    private var statsCardsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "当前连续",
                    value: "\(viewModel?.currentStreak ?? 0)",
                    unit: "天",
                    icon: "flame.fill",
                    color: .orange
                )

                StatCard(
                    title: "最长连续",
                    value: "\(viewModel?.longestStreak ?? 0)",
                    unit: "天",
                    icon: "star.fill",
                    color: .yellow
                )
            }

            HStack(spacing: 12) {
                StatCard(
                    title: "总学习词汇",
                    value: "\(viewModel?.totalWordsLearned ?? 0)",
                    unit: "个",
                    icon: "book.fill",
                    color: .blue
                )

                StatCard(
                    title: "总学习时长",
                    value: viewModel?.formattedTotalStudyTime ?? "0分钟",
                    unit: "",
                    icon: "clock.fill",
                    color: .green
                )
            }
        }
        .padding(.horizontal)
    }

    private var lineChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习趋势")
                .font(.headline)
                .padding(.horizontal)

            WeeklyLineChart(data: viewModel?.chartData ?? [])
                .frame(height: 200)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
        }
    }

    private var calendarHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习日历")
                .font(.headline)
                .padding(.horizontal)

            CalendarHeatmap(dailyProgress: viewModel?.dailyProgressData ?? [])
                .frame(height: 180)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
        }
    }

    private var masteryDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("掌握度分布")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 16) {
                MasteryPieChart(
                    newCount: viewModel?.newCount ?? 0,
                    learningCount: viewModel?.learningCount ?? 0,
                    reviewingCount: viewModel?.reviewingCount ?? 0,
                    masteredCount: viewModel?.masteredCount ?? 0
                )
                .frame(height: 200)

                // Legend
                HStack(spacing: 20) {
                    LegendItem(color: .gray, label: "新学", count: viewModel?.newCount ?? 0)
                    LegendItem(color: .orange, label: "学习中", count: viewModel?.learningCount ?? 0)
                    LegendItem(color: .blue, label: "复习中", count: viewModel?.reviewingCount ?? 0)
                    LegendItem(color: .green, label: "已掌握", count: viewModel?.masteredCount ?? 0)
                }
                .font(.caption)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
    }

    private var achievementWallSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成就墙")
                .font(.headline)
                .padding(.horizontal)

            AchievementWall(
                unlockedAchievements: viewModel?.unlockedAchievements ?? [],
                onAchievementTap: { achievement in
                    // Show achievement details
                }
            )
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(label) (\(count))")
        }
    }
}

#Preview {
    LearningProgressView()
        .modelContainer(for: [DailyProgress.self, UserStats.self, Word.self])
}
