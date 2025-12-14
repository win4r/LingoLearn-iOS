//
//  ListeningTestView.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI
import SwiftData
import AVFoundation

struct ListeningTestView: View {
    let wordCount: Int
    let category: PracticeCategory

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allWords: [Word]
    @Query private var userSettings: [UserSettings]

    @State private var viewModel = PracticeViewModel()
    @State private var selectedAnswer: String? = nil
    @State private var answerSubmitted = false
    @State private var showCorrectAnimation = false
    @State private var showWrongAnimation = false
    @State private var isLoading = true
    @State private var navigateToResults = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var hasPlayedAudio = false

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
                            // Instructions
                            Text("听发音，选择正确的单词")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.top, 40)

                            // Audio control
                            VStack(spacing: 16) {
                                Image(systemName: "headphones.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundStyle(.orange)

                                Button(action: {
                                    playWord(question.word.english)
                                }) {
                                    HStack {
                                        Image(systemName: hasPlayedAudio ? "speaker.wave.2.fill" : "speaker.fill")
                                            .font(.title3)

                                        Text(hasPlayedAudio ? "重新播放" : "播放发音")
                                            .font(.headline)
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 16)
                                    .background(Color.orange)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(.vertical, 20)

                            // Answer options
                            VStack(spacing: 16) {
                                ForEach(question.options, id: \.self) { option in
                                    AnswerOptionButton(
                                        text: option,
                                        state: buttonState(for: option),
                                        action: {
                                            if !answerSubmitted {
                                                handleAnswerSelection(option)
                                            }
                                        }
                                    )
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
        .navigationTitle("听力题")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("退出") {
                    viewModel.stopTimer()
                    speechSynthesizer.stopSpeaking(at: .immediate)
                    dismiss()
                }
            }
        }
        .navigationDestination(isPresented: $navigateToResults) {
            TestResultsView(
                sessionType: .listening,
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
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        .onChange(of: viewModel.currentQuestionIndex) { oldValue, newValue in
            hasPlayedAudio = false
            if let question = viewModel.currentQuestion, !answerSubmitted {
                // Auto-play on new question
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    playWord(question.word.english)
                }
            }
        }
    }

    private func buttonState(for option: String) -> AnswerState {
        if !answerSubmitted {
            return selectedAnswer == option ? .selected : .normal
        } else {
            if option == viewModel.currentQuestion?.correctAnswer {
                return .correct
            } else if option == selectedAnswer {
                return .wrong
            } else {
                return .disabled
            }
        }
    }

    private func playWord(_ word: String) {
        speechSynthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.4 // Slower for learning
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        speechSynthesizer.speak(utterance)
        hasPlayedAudio = true
    }

    private func handleAnswerSelection(_ answer: String) {
        selectedAnswer = answer
        answerSubmitted = true
        viewModel.submitAnswer(answer)

        let isCorrect = answer == viewModel.currentQuestion?.correctAnswer

        if isCorrect {
            withAnimation {
                showCorrectAnimation = true
            }
        } else {
            withAnimation {
                showWrongAnimation = true
            }
        }

        // Auto-advance after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCorrectAnimation = false
                showWrongAnimation = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                selectedAnswer = nil
                answerSubmitted = false
                viewModel.nextQuestion()

                if viewModel.testCompleted {
                    viewModel.saveSession(modelContext: modelContext, sessionType: .listening)
                    navigateToResults = true
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
            testType: .listening,
            timeLimit: timeLimit
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            viewModel.startTimer()

            // Auto-play first word
            if let question = viewModel.currentQuestion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    playWord(question.word.english)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ListeningTestView(wordCount: 10, category: .all)
            .modelContainer(for: [Word.self, StudySession.self, UserSettings.self])
    }
}
