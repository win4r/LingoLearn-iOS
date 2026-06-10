//
//  StatsView.swift
//  LingoLearn
//
//  学习进度：折线图、日历热力图、掌握度分布、成就徽章墙。
//

import Charts
import SwiftData
import SwiftUI
import UIKit

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var rangeDays = 7
    @State private var series: [(day: Date, count: Int)] = []
    @State private var activity: [Date: Int] = [:]
    @State private var distribution: [LearningStatus: Int] = [:]
    @State private var unlockedAt: [String: Date] = [:]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    trendSection
                    heatmapSection
                    masterySection
                    achievementSection
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("学习进度")
        }
        .onAppear { refresh() }
        .onChange(of: rangeDays) { refresh() }
    }

    private func refresh() {
        series = StudyService.dailyLearnedSeries(context: modelContext, days: rangeDays)
        activity = StudyService.activitySeries(context: modelContext, days: 15 * 7)
        distribution = StudyService.statusDistribution(context: modelContext)
        unlockedAt = AchievementEngine.unlockedAt(context: modelContext)
    }

    // MARK: - 学习趋势折线图

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("学习趋势")
                    .font(.headline)
                Spacer()
                Picker("范围", selection: $rangeDays) {
                    Text("近 7 天").tag(7)
                    Text("近 30 天").tag(30)
                }
                .pickerStyle(.segmented)
                .frame(width: 170)
            }

            Chart {
                ForEach(series, id: \.day) { item in
                    AreaMark(
                        x: .value("日期", item.day, unit: .day),
                        y: .value("单词数", item.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.brandPrimary.opacity(0.32), Color.brandPrimary.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("日期", item.day, unit: .day),
                        y: .value("单词数", item.count)
                    )
                    .foregroundStyle(LinearGradient.brand)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .interpolationMethod(.catmullRom)

                    if rangeDays == 7 {
                        PointMark(
                            x: .value("日期", item.day, unit: .day),
                            y: .value("单词数", item.count)
                        )
                        .foregroundStyle(Color.brandPrimary)
                        .symbolSize(36)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: rangeDays == 7 ? 1 : 6)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.defaultDigits).day(), centered: rangeDays == 7)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 200)
            .overlay {
                if series.allSatisfy({ $0.count == 0 }) {
                    Text("暂无学习数据，快去学习吧")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Capsule().fill(Color(.systemGray6)))
                }
            }
        }
        .padding(16)
        .cardSurface()
    }

    // MARK: - 热力图

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习频率")
                .font(.headline)
            HeatmapView(activity: activity, weeks: 15)
            HStack(spacing: 5) {
                Spacer()
                Text("少")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach(0..<5, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(HeatmapView.color(forLevel: level))
                        .frame(width: 12, height: 12)
                }
                Text("多")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .cardSurface()
    }

    // MARK: - 掌握度分布

    private var masterySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("词汇掌握度")
                .font(.headline)

            HStack(spacing: 18) {
                Chart {
                    ForEach(LearningStatus.allCases) { status in
                        SectorMark(
                            angle: .value("数量", distribution[status] ?? 0),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .cornerRadius(4)
                        .foregroundStyle(Self.statusColor(status))
                    }
                }
                .frame(width: 150, height: 150)
                .overlay {
                    VStack(spacing: 0) {
                        Text("\(totalWords)")
                            .font(.title3.bold().monospacedDigit())
                        Text("总词数")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(LearningStatus.allCases) { status in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Self.statusColor(status))
                                .frame(width: 10, height: 10)
                            Text(status.displayName)
                                .font(.subheadline)
                            Spacer()
                            Text("\(distribution[status] ?? 0)")
                                .font(.subheadline.bold().monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .cardSurface()
    }

    private var totalWords: Int {
        LearningStatus.allCases.reduce(0) { $0 + (distribution[$1] ?? 0) }
    }

    static func statusColor(_ status: LearningStatus) -> Color {
        switch status {
        case .new: Color(.systemGray4)
        case .learning: .brandPrimary
        case .mastered: .brandSecondary
        }
    }

    // MARK: - 成就墙

    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("成就徽章")
                    .font(.headline)
                Spacer()
                Text("\(unlockedAt.count) / \(AchievementKind.allCases.count)")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 14) {
                ForEach(AchievementKind.allCases) { kind in
                    AchievementBadge(kind: kind, unlockedAt: unlockedAt[kind.rawValue])
                }
            }
        }
        .padding(16)
        .cardSurface()
    }
}

// MARK: - 热力图组件

struct HeatmapView: View {
    let activity: [Date: Int]
    let weeks: Int

    private let cellSize: CGFloat = 16
    private let spacing: CGFloat = 3

    /// 周一对齐的列起始日期（最旧 → 最新）
    private var weekStarts: [Date] {
        let calendar = Calendar.current
        let today = Date().startOfDay
        // 求本周周一
        let weekday = calendar.component(.weekday, from: today) // 1=周日
        let mondayOffset = (weekday + 5) % 7
        let thisMonday = today.addingDays(-mondayOffset)
        return (0..<weeks).reversed().map { thisMonday.addingDays(-7 * $0) }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: spacing) {
                weekdayLabels
                ForEach(weekStarts, id: \.self) { monday in
                    weekColumn(monday: monday)
                }
            }
        }
        .defaultScrollAnchor(.trailing)
    }

    private var weekdayLabels: some View {
        VStack(alignment: .trailing, spacing: spacing) {
            Color.clear.frame(width: 18, height: 14) // 月份行占位
            ForEach(0..<7, id: \.self) { row in
                Text(row == 0 ? "一" : row == 2 ? "三" : row == 4 ? "五" : " ")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: cellSize)
            }
        }
    }

    private func weekColumn(monday: Date) -> some View {
        let calendar = Calendar.current
        let showMonth = calendar.component(.day, from: monday) <= 7
        let today = Date().startOfDay

        return VStack(spacing: spacing) {
            Text(showMonth ? "\(calendar.component(.month, from: monday))月" : " ")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .frame(height: 14)

            ForEach(0..<7, id: \.self) { row in
                let day = monday.addingDays(row)
                let count = activity[day] ?? 0
                RoundedRectangle(cornerRadius: 3)
                    .fill(day > today ? Color.clear : Self.color(forLevel: Self.level(for: count)))
                    .frame(width: cellSize, height: cellSize)
                    .overlay {
                        if day == today {
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.brandPrimary, lineWidth: 1.5)
                        }
                    }
                    .accessibilityLabel("\(day.formatted(date: .abbreviated, time: .omitted)) 学习 \(count) 次")
            }
        }
    }

    static func level(for count: Int) -> Int {
        switch count {
        case 0: 0
        case 1...2: 1
        case 3...5: 2
        case 6...9: 3
        default: 4
        }
    }

    static func color(forLevel level: Int) -> Color {
        switch level {
        case 0: Color(.systemGray5)
        case 1: Color.brandSecondary.opacity(0.3)
        case 2: Color.brandSecondary.opacity(0.55)
        case 3: Color.brandSecondary.opacity(0.8)
        default: Color.brandPrimary
        }
    }
}

// MARK: - 成就徽章

struct AchievementBadge: View {
    let kind: AchievementKind
    let unlockedAt: Date?

    private var unlocked: Bool { unlockedAt != nil }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(unlocked ? AnyShapeStyle(LinearGradient.brand) : AnyShapeStyle(Color(.systemGray5)))
                    .frame(width: 56, height: 56)
                Image(systemName: unlocked ? kind.icon : "lock.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(unlocked ? .white : Color(.systemGray2))
            }
            .shadow(color: unlocked ? Color.brandPrimary.opacity(0.35) : .clear, radius: 6, y: 3)

            Text(kind.title)
                .font(.caption.bold())
                .foregroundStyle(unlocked ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(unlocked
                 ? unlockedAt!.formatted(.dateTime.month(.defaultDigits).day())
                 : kind.subtitle)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .opacity(unlocked ? 1 : 0.75)
    }
}
