//
//  FillInBlankView.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI
import SwiftData

struct FillInBlankView: View {
    let wordCount: Int
    let category: PracticeCategory

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allWords: [Word]
    @Query private var userSettings: [UserSettings]

    @State private var viewModel = PracticeViewModel()
    @State private var userAnswer: String = ""
    @State private var answerSubmitted = false
    @State private var showCorrectAnimation = false
    @State private var showWrongAnimation = false
    @State private var isLoading = true
    @State private var navigateToResults = false
    @FocusState private var isTextFieldFocused: Bool

    private var filteredWords: [Word] {
        if category == .all {
            return Array(allWords.shuffled().prefix(wordCount))
        } else {
            let categoryEnum: WordCategory = category == .cet4 ? .cet4 : .cet6
            let filtered = allWords.filter { $0.category == categoryEnum }
            return Array(filtered.shuffled().prefix(wordCount))
        }
    }

    private var timeLimit: Double {
        Double(userSettings.first?.questionTimeLimit ?? 15)
    }

    private var isAnswerCorrect: Bool {
        guard let correctAnswer = viewModel.currentQuestion?.correctAnswer else { return false }
        return userAnswer.lowercased().trimmingCharacters(in: .whitespaces) == correctAnswer
    }

    var body: some View {
        ZStack {
            if isLoading {
                LoadingView(message: "准备测试...")
            } else if viewModel.testCompleted {
                Color.clear
            } else {
                VStack(spacing: 0) {
                    // Timer bar
                    CountdownTimerBar(
                        timeRemaining: viewModel.timeRemaining,
                        totalTime: viewModel.questionTimeLimit
                    )
                    .padding()

                    // Progress indicator
                    HStack {
                        Text("题目 \(viewModel.currentQuestionIndex + 1) / \(viewModel.totalQuestions)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("正确: \(viewModel.correctAnswers)")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal)

                    // Question area
                    if let question = viewModel.currentQuestion {
                        VStack(spacing: 32) {
                            // Chinese meaning
                            VStack(spacing: 16) {
                                Text("请写出对应的英文单词")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)

                                Text(question.word.chinese)
                                    .font(.system(size: 36, weight: .bold))
                                    .multilineTextAlignment(.center)

                                if !question.word.exampleSentence.isEmpty {
                                    VStack(spacing: 4) {
                                        Text("例句:")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        Text(question.word.exampleTranslation)
                                            .font(.body)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(.top, 8)
                                }
                            }
                            .padding(.top, 40)
                            .padding(.horizontal)

                            // Answer input
                            VStack(spacing: 16) {
                                TextField("输入英文单词", text: $userAnswer)
                                    .textFieldStyle(.plain)
                                    .font(.title2)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                answerSubmitted ?
                                                (isAnswerCorrect ? Color.green : Color.red) :
                                                Color.gray.opacity(0.3),
                                                lineWidth: 2
                                            )
                                    )
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .focused($isTextFieldFocused)
                                    .disabled(answerSubmitted)

                                // Show correct answer if wrong
                                if answerSubmitted && !isAnswerCorrect {
                                    HStack {
                                        Text("正确答案:")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)

                                        Text(question.word.english)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.green)

                                        Text("[\(question.word.phonetic)]")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }

                                // Submit button
                                if !answerSubmitted {
                                    Button(action: handleSubmit) {
                                        Text("提交")
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(userAnswer.isEmpty ? Color.gray : Color.accentColor)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .disabled(userAnswer.isEmpty)
                                }
                            }
                            .padding(.horizontal)

                            Spacer()
                        }
                    }
                }
            }

            // Answer animations overlay
            if showCorrectAnimation {
                CorrectAnswerAnimation()
                    .transition(.scale.combined(with: .opacity))
            }

            if showWrongAnimation {
                WrongAnswerAnimation()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle("填空题")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("退出") {
                    viewModel.stopTimer()
                    dismiss()
                }
            }
        }
        .navigationDestination(isPresented: $navigateToResults) {
            TestResultsView(
                sessionType: .fillInBlank,
                correctAnswers: viewModel.correctAnswers,
                wrongAnswers: viewModel.wrongAnswers,
                totalQuestions: viewModel.totalQuestions,
                duration: Date().timeIntervalSince(viewModel.sessionStartTime ?? Date())
            )
        }
        .onAppear {
            setupTest()
        }
        .onDisappear {
            viewModel.stopTimer()
        }
    }

    private func handleSubmit() {
        answerSubmitted = true
        isTextFieldFocused = false
        viewModel.submitAnswer(userAnswer)

        if isAnswerCorrect {
            withAnimation {
                showCorrectAnimation = true
            }
        } else {
            withAnimation {
                showWrongAnimation = true
            }
        }

        // Auto-advance after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showCorrectAnimation = false
                showWrongAnimation = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                userAnswer = ""
                answerSubmitted = false
                viewModel.nextQuestion()

                if viewModel.testCompleted {
                    viewModel.saveSession(modelContext: modelContext, sessionType: .fillInBlank)
                    navigateToResults = true
                } else {
                    isTextFieldFocused = true
                }
            }
        }
    }

    private func setupTest() {
        let words = filteredWords

        if words.isEmpty {
            isLoading = false
            return
        }

        viewModel.setupTest(
            words: words,
            testType: .fillInBlank,
            timeLimit: timeLimit
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            viewModel.startTimer()
            isTextFieldFocused = true
        }
    }
}

#Preview {
    NavigationStack {
        FillInBlankView(wordCount: 10, category: .all)
            .modelContainer(for: [Word.self, StudySession.self, UserSettings.self])
    }
}
