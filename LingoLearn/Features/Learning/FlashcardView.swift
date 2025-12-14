//
//  FlashcardView.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI
import SwiftData

struct FlashcardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: FlashcardViewModel?

    let mode: LearningMode

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                headerSection

                // Card Stack
                if let vm = viewModel, vm.hasMoreCards {
                    FlashcardStack(
                        words: vm.currentWords,
                        currentIndex: vm.currentIndex,
                        onSwipe: { direction in
                            vm.handleSwipe(direction: direction)
                        }
                    )
                    .padding(.horizontal)
                } else if let vm = viewModel, !vm.hasMoreCards && !vm.currentWords.isEmpty {
                    // All cards completed
                    Spacer()
                    completionView
                    Spacer()
                } else {
                    // No words available
                    Spacer()
                    noWordsView
                    Spacer()
                }

                // Instructions
                instructionsSection

                Spacer(minLength: 20)
            }
        }
        .navigationTitle(mode == .learning ? "学习模式" : "复习模式")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = FlashcardViewModel(modelContext: modelContext, mode: mode)
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.showSummary ?? false },
            set: { if !$0 { viewModel?.showSummary = false } }
        )) {
            if let vm = viewModel {
                SessionSummarySheet(
                    stats: vm.sessionStats,
                    onContinue: {
                        vm.reset()
                    },
                    onHome: {
                        dismiss()
                    }
                )
            }
        }
    }

    private var headerSection: some View {
        HStack {
            if let vm = viewModel {
                Text("进度: \(vm.currentIndex)/\(vm.currentWords.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("已学: \(vm.sessionStats.totalReviewed)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private var instructionsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 30) {
                InstructionItem(icon: "hand.thumbsdown.fill", text: "不认识", color: .red)
                InstructionItem(icon: "heart.fill", text: "收藏", color: .yellow)
                InstructionItem(icon: "hand.thumbsup.fill", text: "认识", color: .green)
            }

            Text("点击卡片翻转 · 滑动作答")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("完成!")
                .font(.title)
                .fontWeight(.bold)

            Text("所有单词已学习完成")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var noWordsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 80))
                .foregroundStyle(.gray)

            Text("暂无单词")
                .font(.title)
                .fontWeight(.bold)

            Text(mode == .learning ? "暂时没有新单词需要学习" : "没有单词需要复习")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct InstructionItem: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(8)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        FlashcardView(mode: .learning)
            .modelContainer(for: [Word.self, UserStats.self, DailyProgress.self, UserSettings.self])
    }
}
