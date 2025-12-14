//
//  PracticeMenuView.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI
import SwiftData

enum PracticeCategory: String, Codable, CaseIterable {
    case all = "All"
    case cet4 = "CET-4"
    case cet6 = "CET-6"
}

struct TestType {
    let id: SessionType
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct PracticeMenuView: View {
    @State private var selectedWordCount: Int = 10
    @State private var selectedCategory: PracticeCategory = .all
    @State private var selectedTestType: SessionType? = nil
    @State private var showingTest = false

    private let testTypes: [TestType] = [
        TestType(
            id: .multipleChoice,
            icon: "list.bullet.circle.fill",
            title: "选择题",
            description: "从四个选项中选择正确答案",
            color: .blue
        ),
        TestType(
            id: .fillInBlank,
            icon: "pencil.circle.fill",
            title: "填空题",
            description: "根据中文意思填写英文单词",
            color: .green
        ),
        TestType(
            id: .listening,
            icon: "headphones.circle.fill",
            title: "听力题",
            description: "听发音选择正确的单词",
            color: .orange
        )
    ]

    private let wordCountOptions = [10, 20, 30, 50]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Test type selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("选择测试类型")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(testTypes, id: \.id) { testType in
                            TestTypeCard(
                                testType: testType,
                                isSelected: selectedTestType == testType.id,
                                action: {
                                    withAnimation {
                                        selectedTestType = testType.id
                                    }
                                }
                            )
                            .padding(.horizontal)
                        }
                    }

                    // Word count selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("题目数量")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            ForEach(wordCountOptions, id: \.self) { count in
                                Button(action: {
                                    withAnimation {
                                        selectedWordCount = count
                                    }
                                }) {
                                    Text("\(count)")
                                        .font(.body)
                                        .fontWeight(selectedWordCount == count ? .semibold : .regular)
                                        .foregroundStyle(selectedWordCount == count ? .white : .primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            selectedWordCount == count ?
                                            Color.accentColor : Color.gray.opacity(0.1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Category filter
                    VStack(alignment: .leading, spacing: 12) {
                        Text("词库分类")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            ForEach(PracticeCategory.allCases, id: \.self) { category in
                                Button(action: {
                                    withAnimation {
                                        selectedCategory = category
                                    }
                                }) {
                                    Text(category.rawValue)
                                        .font(.body)
                                        .fontWeight(selectedCategory == category ? .semibold : .regular)
                                        .foregroundStyle(selectedCategory == category ? .white : .primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            selectedCategory == category ?
                                            Color.accentColor : Color.gray.opacity(0.1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Start button
                    Button(action: {
                        if selectedTestType != nil {
                            showingTest = true
                        }
                    }) {
                        Text("开始测试")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedTestType == nil ? Color.gray : Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(selectedTestType == nil)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .padding(.vertical)
            }
            .navigationTitle("练习测试")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $showingTest) {
                if let testType = selectedTestType {
                    TestViewRouter(
                        testType: testType,
                        wordCount: selectedWordCount,
                        category: selectedCategory
                    )
                }
            }
        }
    }
}

struct TestTypeCard: View {
    let testType: TestType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: testType.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(testType.color)
                    .frame(width: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text(testType.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(testType.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(testType.color)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? testType.color.opacity(0.1) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? testType.color : Color.gray.opacity(0.2), lineWidth: 2)
            )
        }
    }
}

struct TestViewRouter: View {
    let testType: SessionType
    let wordCount: Int
    let category: PracticeCategory
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        switch testType {
        case .multipleChoice:
            MultipleChoiceView(wordCount: wordCount, category: category)
                .environment(\.modelContext, modelContext)
        case .fillInBlank:
            FillInBlankView(wordCount: wordCount, category: category)
                .environment(\.modelContext, modelContext)
        case .listening:
            ListeningTestView(wordCount: wordCount, category: category)
                .environment(\.modelContext, modelContext)
        default:
            Text("Test type not implemented")
        }
    }
}

#Preview {
    PracticeMenuView()
}
