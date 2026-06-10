//
//  PracticeSetupView.swift
//  LingoLearn
//
//  练习配置：题型 / 题量 / 每题时间。
//

import SwiftData
import SwiftUI
import UIKit

struct QuizConfig: Identifiable {
    let id = UUID()
    /// nil = 每题随机题型（随机测试）
    var type: QuizType?
    var count: Int = 10
    var secondsPerQuestion: Int = 15

    static let random = QuizConfig(type: nil, count: 10, secondsPerQuestion: 15)
}

struct PracticeSetupView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var selectedType: QuizType? = .choice
    @State private var count = 10
    @State private var seconds = 15
    @State private var runningConfig: QuizConfig?
    @State private var wordCount = 0

    private let countOptions = [5, 10, 15, 20]
    private let secondOptions = [10, 15, 20, 30]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    typeSection
                    pickerSection(
                        title: "题目数量",
                        options: countOptions,
                        selection: $count,
                        formatter: { "\($0) 题" }
                    )
                    pickerSection(
                        title: "每题时间",
                        options: secondOptions,
                        selection: $seconds,
                        formatter: { "\($0) 秒" }
                    )
                    startButton
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("练习测试")
        }
        .onAppear { wordCount = StudyService.allWords(context: modelContext).count }
        .fullScreenCover(item: $runningConfig) { config in
            QuizRunView(config: config)
        }
    }

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("题型")
                .font(.headline)

            ForEach(QuizType.allCases) { type in
                typeRow(
                    icon: type.icon,
                    title: type.displayName,
                    detail: type.detail,
                    isSelected: selectedType == type
                ) {
                    selectedType = type
                }
            }
            typeRow(
                icon: "dice.fill",
                title: "随机混合",
                detail: "三种题型随机出现",
                isSelected: selectedType == nil
            ) {
                selectedType = nil
            }
        }
    }

    private func typeRow(
        icon: String,
        title: String,
        detail: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? AnyShapeStyle(LinearGradient.brand) : AnyShapeStyle(.secondary))
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.brandPrimary : Color(.systemGray4))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? Color.brandPrimary : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func pickerSection(
        title: String,
        options: [Int],
        selection: Binding<Int>,
        formatter: @escaping (Int) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            HStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    Button {
                        Haptics.tap()
                        selection.wrappedValue = option
                    } label: {
                        Text(formatter(option))
                            .font(.subheadline.bold())
                            .foregroundStyle(selection.wrappedValue == option ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selection.wrappedValue == option
                                          ? AnyShapeStyle(LinearGradient.brand)
                                          : AnyShapeStyle(Color(.secondarySystemGroupedBackground)))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var startButton: some View {
        VStack(spacing: 8) {
            Button {
                Haptics.medium()
                runningConfig = QuizConfig(type: selectedType, count: count, secondsPerQuestion: seconds)
            } label: {
                Label("开始练习", systemImage: "play.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient.brand)
                            .shadow(color: Color.brandPrimary.opacity(0.35), radius: 10, y: 5)
                    )
            }
            .buttonStyle(.plain)
            .disabled(wordCount < 4)

            if wordCount < 4 {
                Text("词库单词不足，无法生成题目")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 6)
    }
}
