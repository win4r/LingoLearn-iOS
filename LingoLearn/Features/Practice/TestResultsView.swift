//
//  TestResultsView.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI
import SwiftData

struct TestResultsView: View {
    let sessionType: SessionType
    let correctAnswers: Int
    let wrongAnswers: [WrongAnswer]
    let totalQuestions: Int
    let duration: TimeInterval

    @Environment(\.dismiss) private var dismiss

    private var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions) * 100
    }

    private var accuracyColor: Color {
        if accuracy >= 90 {
            return .green
        } else if accuracy >= 70 {
            return .orange
        } else {
            return .red
        }
    }

    private var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: accuracy >= 70 ? "star.fill" : "hand.thumbsup.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(accuracyColor)

                    Text(accuracy >= 90 ? "优秀!" : accuracy >= 70 ? "很好!" : "继续加油!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.top, 40)

                // Accuracy ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                        .frame(width: 200, height: 200)

                    Circle()
                        .trim(from: 0, to: accuracy / 100)
                        .stroke(
                            accuracyColor,
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1.0), value: accuracy)

                    VStack(spacing: 4) {
                        Text("\(Int(accuracy))%")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(accuracyColor)

                        Text("正确率")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Stats cards
                VStack(spacing: 16) {
                    ResultStatCard(
                        icon: "clock.fill",
                        title: "用时",
                        value: formattedDuration,
                        color: .blue
                    )

                    ResultStatCard(
                        icon: "book.fill",
                        title: "题目总数",
                        value: "\(totalQuestions)",
                        color: .purple
                    )

                    HStack(spacing: 16) {
                        ResultStatCard(
                            icon: "checkmark.circle.fill",
                            title: "正确",
                            value: "\(correctAnswers)",
                            color: .green
                        )

                        ResultStatCard(
                            icon: "xmark.circle.fill",
                            title: "错误",
                            value: "\(wrongAnswers.count)",
                            color: .red
                        )
                    }
                }
                .padding(.horizontal)

                // Wrong answers section
                if !wrongAnswers.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("错题回顾")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            ForEach(Array(wrongAnswers.enumerated()), id: \.offset) { index, wrongAnswer in
                                WrongAnswerCard(
                                    number: index + 1,
                                    wrongAnswer: wrongAnswer,
                                    sessionType: sessionType
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Action buttons
                VStack(spacing: 12) {
                    if !wrongAnswers.isEmpty {
                        Button(action: {
                            // TODO: Navigate to study session with wrong words
                        }) {
                            HStack {
                                Image(systemName: "book.circle.fill")
                                Text("复习错题")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    Button(action: {
                        // Dismiss all the way back to practice menu
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "house.fill")
                            Text("返回主页")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("测试结果")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}

struct ResultStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct WrongAnswerCard: View {
    let number: Int
    let wrongAnswer: WrongAnswer
    let sessionType: SessionType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(number).")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            // Show based on test type
            if sessionType == .multipleChoice {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(wrongAnswer.word.english)
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text(wrongAnswer.word.phonetic)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text("你选择了: \(wrongAnswer.userAnswer)")
                            .font(.body)
                            .foregroundStyle(.red)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("正确答案: \(wrongAnswer.correctAnswer)")
                            .font(.body)
                            .foregroundStyle(.green)
                    }
                }
            } else if sessionType == .fillInBlank {
                VStack(alignment: .leading, spacing: 8) {
                    Text(wrongAnswer.word.chinese)
                        .font(.title3)
                        .fontWeight(.semibold)

                    if !wrongAnswer.userAnswer.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Text("你填写了: \(wrongAnswer.userAnswer)")
                                .font(.body)
                                .foregroundStyle(.red)
                        }
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("正确答案: \(wrongAnswer.correctAnswer)")
                            .font(.body)
                            .foregroundStyle(.green)

                        Text("[\(wrongAnswer.word.phonetic)]")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if sessionType == .listening {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "headphones.circle.fill")
                            .foregroundStyle(.orange)
                        Text("听力题")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text("你选择了: \(wrongAnswer.userAnswer)")
                            .font(.body)
                            .foregroundStyle(.red)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("正确答案: \(wrongAnswer.correctAnswer)")
                            .font(.body)
                            .foregroundStyle(.green)

                        Text("[\(wrongAnswer.word.phonetic)]")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text(wrongAnswer.word.chinese)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }

            // Example sentence
            if !wrongAnswer.word.exampleSentence.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("例句:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(wrongAnswer.word.exampleSentence)
                        .font(.subheadline)
                        .italic()

                    Text(wrongAnswer.word.exampleTranslation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.red.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        TestResultsView(
            sessionType: .multipleChoice,
            correctAnswers: 8,
            wrongAnswers: [],
            totalQuestions: 10,
            duration: 125.5
        )
    }
}
