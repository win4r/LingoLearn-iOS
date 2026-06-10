//
//  QuizRunView.swift
//  LingoLearn
//
//  答题流程：倒计时进度条、即时对错反馈动画、结算与错题回顾。
//

import Combine
import SwiftData
import SwiftUI
import UIKit

struct QuizRunView: View {
    let config: QuizConfig

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    enum Phase {
        case loading
        case answering
        case feedback
        case finished
    }

    @State private var allWords: [Word] = []
    @State private var questions: [QuizQuestion] = []
    @State private var currentIndex = 0
    @State private var answers: [QuizAnswerRecord] = []
    @State private var phase: Phase = .loading

    // 当前题作答状态
    @State private var selectedIndex: Int?
    @State private var spellingInput = ""
    @State private var shakeTrigger = 0
    @State private var checkmarkScale = 0.0
    @State private var questionStart = Date()
    @State private var remaining: Double = 0
    @State private var totalElapsed: TimeInterval = 0
    @State private var celebrationQueue: [AchievementKind] = []

    @FocusState private var spellingFocused: Bool

    private let ticker = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    private var currentQuestion: QuizQuestion? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    private var limit: Double { Double(config.secondsPerQuestion) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                switch phase {
                case .loading:
                    LoadingStateView(text: "正在出题…")
                case .answering, .feedback:
                    questionContent
                case .finished:
                    QuizResultView(
                        answers: answers,
                        totalElapsed: totalElapsed,
                        onRetryAll: { restart(with: makeInitialQuestions()) },
                        onRetryWrong: { retryWrongOnes() },
                        onDone: { dismiss() }
                    )
                }

                if let kind = celebrationQueue.first {
                    AchievementCelebrationView(kind: kind) {
                        withAnimation { _ = celebrationQueue.removeFirst() }
                    }
                    .transition(.opacity)
                    .zIndex(10)
                }
            }
            .navigationTitle(phase == .finished ? "练习结果" : "练习中")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.tap()
                        SpeechService.shared.stop()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("关闭")
                }
            }
        }
        .task { start() }
        .onReceive(ticker) { _ in tick() }
    }

    // MARK: - 出题与流程控制

    private func makeInitialQuestions() -> [QuizQuestion] {
        QuizEngine.makeQuestions(type: config.type, count: config.count, allWords: allWords)
    }

    private func start() {
        guard phase == .loading else { return }
        allWords = StudyService.allWords(context: modelContext)
        restart(with: makeInitialQuestions())
    }

    private func restart(with newQuestions: [QuizQuestion]) {
        questions = newQuestions
        currentIndex = 0
        answers = []
        totalElapsed = 0
        guard !questions.isEmpty else {
            dismiss()
            return
        }
        beginQuestion()
    }

    private func beginQuestion() {
        selectedIndex = nil
        spellingInput = ""
        checkmarkScale = 0
        questionStart = Date()
        remaining = limit
        phase = .answering

        if let question = currentQuestion, question.type == .listening {
            SpeechService.shared.speak(question.word.english)
        }
        if currentQuestion?.type == .spelling {
            spellingFocused = true
        }
    }

    private func tick() {
        guard phase == .answering else { return }
        remaining = max(0, limit - Date().timeIntervalSince(questionStart))
        if remaining <= 0 {
            submit(answerText: nil, chosenIndex: nil, timedOut: true)
        }
    }

    /// 统一判分入口
    private func submit(answerText: String?, chosenIndex: Int?, timedOut: Bool) {
        guard phase == .answering, let question = currentQuestion else { return }
        totalElapsed += min(limit, Date().timeIntervalSince(questionStart))

        let isCorrect: Bool
        if timedOut {
            isCorrect = false
        } else {
            switch question.type {
            case .spelling:
                isCorrect = QuizEngine.checkSpelling(input: answerText ?? "", answer: question.word.english)
            case .choice, .listening:
                isCorrect = chosenIndex == question.correctIndex
            }
        }

        selectedIndex = chosenIndex
        spellingFocused = false
        answers.append(QuizAnswerRecord(
            question: question,
            userAnswer: timedOut ? nil : answerText ?? chosenIndex.map { question.options[$0] },
            isCorrect: isCorrect
        ))

        phase = .feedback
        if isCorrect {
            Haptics.success()
            SoundFX.correct()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                checkmarkScale = 1
            }
        } else {
            Haptics.error()
            SoundFX.wrong()
            shakeTrigger += 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (isCorrect ? 0.9 : 1.5)) {
            advance()
        }
    }

    private func advance() {
        guard phase == .feedback else { return }
        if currentIndex + 1 < questions.count {
            currentIndex += 1
            beginQuestion()
        } else {
            finishQuiz()
        }
    }

    private func finishQuiz() {
        phase = .finished
        SoundFX.complete()
        let correct = answers.filter { $0.isCorrect }.count
        StudyService.recordQuiz(correct: correct, total: answers.count, context: modelContext)
        let newly = AchievementEngine.evaluate(
            context: modelContext,
            quizResult: (correct: correct, total: answers.count)
        )
        celebrationQueue = newly
    }

    private func retryWrongOnes() {
        let wrong = answers.filter { !$0.isCorrect }
        let newQuestions = wrong.map {
            QuizEngine.makeQuestion(type: $0.question.type, word: $0.question.word, allWords: allWords)
        }
        restart(with: newQuestions)
    }

    // MARK: - 答题界面

    private var questionContent: some View {
        VStack(spacing: 20) {
            timerBar
            header

            if let question = currentQuestion {
                ScrollView {
                    VStack(spacing: 22) {
                        prompt(for: question)
                        answerArea(for: question)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .scrollDismissesKeyboard(.never)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 8)
    }

    private var timerBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                Capsule()
                    .fill(remaining / limit > 0.3 ? AnyShapeStyle(LinearGradient.brand) : AnyShapeStyle(Color.red))
                    .frame(width: max(8, proxy.size.width * remaining / limit))
                    .animation(.linear(duration: 0.05), value: remaining)
            }
        }
        .frame(height: 8)
        .padding(.horizontal, 20)
        .accessibilityLabel("剩余 \(Int(remaining)) 秒")
    }

    private var header: some View {
        HStack {
            Text("第 \(min(currentIndex + 1, questions.count)) / \(questions.count) 题")
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(.secondary)
            Spacer()
            Label("\(Int(remaining.rounded()))s", systemImage: "timer")
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(remaining / limit > 0.3 ? Color.secondary : .red)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func prompt(for question: QuizQuestion) -> some View {
        VStack(spacing: 12) {
            switch question.type {
            case .choice:
                Text(question.word.english)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(question.word.phonetic)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("选出正确的中文释义")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

            case .spelling:
                Text(question.word.meaning)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text("共 \(question.word.english.count) 个字母")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("拼写出对应的英文单词")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

            case .listening:
                Button {
                    Haptics.tap()
                    SpeechService.shared.speak(question.word.english)
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                            .frame(width: 96, height: 96)
                            .background(Circle().fill(LinearGradient.brand))
                            .shadow(color: Color.brandPrimary.opacity(0.4), radius: 12, y: 5)
                        Text("点击重新播放")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(phase == .feedback)
                Text("听发音，选出正确的单词")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .cardSurface()
        .overlay(alignment: .topTrailing) {
            if phase == .feedback {
                feedbackBadge
                    .padding(12)
            }
        }
    }

    private var feedbackBadge: some View {
        Group {
            if answers.last?.isCorrect == true {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.green)
                    .scaleEffect(checkmarkScale)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private func answerArea(for question: QuizQuestion) -> some View {
        switch question.type {
        case .choice, .listening:
            VStack(spacing: 12) {
                ForEach(question.options.indices, id: \.self) { index in
                    optionButton(question: question, index: index)
                }
            }
        case .spelling:
            spellingArea(for: question)
        }
    }

    private func optionButton(question: QuizQuestion, index: Int) -> some View {
        let isCorrectOption = index == question.correctIndex
        let isChosen = index == selectedIndex
        let revealing = phase == .feedback

        return Button {
            submit(answerText: nil, chosenIndex: index, timedOut: false)
        } label: {
            HStack {
                Text(question.options[index])
                    .font(question.type == .listening ? .headline : .subheadline.bold())
                    .foregroundStyle(optionForeground(revealing: revealing, correct: isCorrectOption, chosen: isChosen))
                    .multilineTextAlignment(.leading)
                Spacer()
                if revealing && isCorrectOption {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .scaleEffect(isChosen ? checkmarkScale : 1)
                } else if revealing && isChosen && !isCorrectOption {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(optionBackground(revealing: revealing, correct: isCorrectOption, chosen: isChosen))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(optionBorder(revealing: revealing, correct: isCorrectOption, chosen: isChosen), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(revealing)
        .shake(trigger: revealing && isChosen && !isCorrectOption ? shakeTrigger : 0)
    }

    private func optionForeground(revealing: Bool, correct: Bool, chosen: Bool) -> Color {
        guard revealing else { return .primary }
        if correct { return .green }
        if chosen { return .red }
        return .secondary
    }

    private func optionBackground(revealing: Bool, correct: Bool, chosen: Bool) -> Color {
        guard revealing else { return Color(.secondarySystemGroupedBackground) }
        if correct { return .green.opacity(0.12) }
        if chosen { return .red.opacity(0.12) }
        return Color(.secondarySystemGroupedBackground)
    }

    private func optionBorder(revealing: Bool, correct: Bool, chosen: Bool) -> Color {
        guard revealing else { return .clear }
        if correct { return .green }
        if chosen { return .red }
        return .clear
    }

    private func spellingArea(for question: QuizQuestion) -> some View {
        VStack(spacing: 14) {
            TextField("输入英文单词", text: $spellingInput)
                .textFieldStyle(.plain)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($spellingFocused)
                .submitLabel(.done)
                .onSubmit { submitSpelling() }
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(spellingBorderColor, lineWidth: 2)
                        )
                )
                .disabled(phase == .feedback)
                .shake(trigger: shakeTrigger)

            if phase == .feedback, answers.last?.isCorrect == false {
                VStack(spacing: 4) {
                    Text("正确答案")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(currentQuestion?.word.english ?? "")
                        .font(.title3.bold())
                        .foregroundStyle(.green)
                }
                .transition(.opacity)
            }

            if phase == .answering {
                Button {
                    submitSpelling()
                } label: {
                    Text("确认")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: 14).fill(LinearGradient.brand))
                }
                .buttonStyle(.plain)
                .disabled(spellingInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var spellingBorderColor: Color {
        guard phase == .feedback else { return .clear }
        return answers.last?.isCorrect == true ? .green : .red
    }

    private func submitSpelling() {
        let text = spellingInput.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        Haptics.tap()
        submit(answerText: text, chosenIndex: nil, timedOut: false)
    }
}

// MARK: - 结算页

struct QuizResultView: View {
    let answers: [QuizAnswerRecord]
    let totalElapsed: TimeInterval
    let onRetryAll: () -> Void
    let onRetryWrong: () -> Void
    let onDone: () -> Void

    private var correctCount: Int { answers.filter { $0.isCorrect }.count }
    private var accuracy: Double {
        answers.isEmpty ? 0 : Double(correctCount) / Double(answers.count)
    }
    private var wrongAnswers: [QuizAnswerRecord] { answers.filter { !$0.isCorrect } }

    private var elapsedText: String {
        let seconds = Int(totalElapsed.rounded())
        return seconds < 60 ? "\(seconds) 秒" : "\(seconds / 60) 分 \(seconds % 60) 秒"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                summaryCard
                if !wrongAnswers.isEmpty {
                    wrongList
                }
                buttons
            }
            .padding(20)
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 16) {
            Text(accuracy >= 0.8 ? "表现出色 🎉" : accuracy >= 0.5 ? "继续加油 💪" : "多多练习 📖")
                .font(.title3.bold())

            ZStack {
                ProgressRing(progress: accuracy, lineWidth: 12)
                    .frame(width: 130, height: 130)
                VStack(spacing: 0) {
                    Text("\(Int((accuracy * 100).rounded()))%")
                        .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                    Text("正确率")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 22) {
                Label("\(correctCount) 对", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Label("\(answers.count - correctCount) 错", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Label(elapsedText, systemImage: "clock.fill")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .cardSurface()
    }

    private var wrongList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("错题回顾（\(wrongAnswers.count)）")
                .font(.headline)

            ForEach(wrongAnswers) { record in
                HStack(spacing: 12) {
                    Button {
                        Haptics.tap()
                        SpeechService.shared.speak(record.question.word.english)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundStyle(Color.brandPrimary)
                            .padding(8)
                            .background(Circle().fill(Color.brandPrimary.opacity(0.12)))
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(record.question.word.english)
                            .font(.subheadline.bold())
                        Text(record.question.word.meaning)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(record.userAnswer ?? "超时未答")
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                            .lineLimit(1)
                        Text(record.question.type.displayName)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
        }
    }

    private var buttons: some View {
        VStack(spacing: 10) {
            if !wrongAnswers.isEmpty {
                Button {
                    Haptics.medium()
                    onRetryWrong()
                } label: {
                    Label("错题再练", systemImage: "arrow.uturn.left")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(LinearGradient.brand))
                }
                .buttonStyle(.plain)
            }

            Button {
                Haptics.medium()
                onRetryAll()
            } label: {
                Label("再练一组", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundStyle(Color.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.brandPrimary, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)

            Button {
                Haptics.tap()
                onDone()
            } label: {
                Text("完成")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
    }
}
