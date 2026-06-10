//
//  LearnSessionView.swift
//  LingoLearn
//
//  单词卡学习会话：3D 翻转、三向滑动评分、TTS、本轮统计与成就庆祝。
//

import SwiftData
import SwiftUI
import UIKit

struct LearnSessionView: View {
    enum Mode {
        case newWords
        case review

        var title: String {
            switch self {
            case .newWords: "学习新词"
            case .review: "快速复习"
            }
        }
    }

    let mode: Mode

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKeys.dailyGoal) private var dailyGoal = 20
    @AppStorage(SettingsKeys.autoPlayPronunciation) private var autoPlay = true

    @State private var queue: [Word] = []
    @State private var sessionTotal = 0
    @State private var knownCount = 0
    @State private var forgotCount = 0
    @State private var favoriteCount = 0
    @State private var loaded = false
    @State private var showSummary = false
    @State private var celebrationQueue: [AchievementKind] = []

    @State private var dragOffset: CGSize = .zero
    @State private var flipped = false
    @State private var isSwipingOut = false

    private var gradedCount: Int { sessionTotal - queue.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if !loaded {
                    LoadingStateView(text: "正在准备卡片…")
                } else if sessionTotal == 0 {
                    emptyState
                } else {
                    sessionContent
                }

                if showSummary {
                    summaryOverlay
                }

                if let kind = celebrationQueue.first {
                    AchievementCelebrationView(kind: kind) {
                        withAnimation { _ = celebrationQueue.removeFirst() }
                    }
                    .transition(.opacity)
                    .zIndex(10)
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("关闭")
                }
            }
        }
        .task { loadIfNeeded() }
    }

    // MARK: - 主内容

    private var sessionContent: some View {
        VStack(spacing: 16) {
            progressHeader

            ZStack {
                // 底下垫两张卡营造卡堆层次
                ForEach(Array(queue.dropFirst().prefix(2).enumerated()), id: \.element.persistentModelID) { index, _ in
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                        .scaleEffect(1 - CGFloat(index + 1) * 0.04)
                        .offset(y: CGFloat(index + 1) * 12)
                }

                if let word = queue.first {
                    WordCardView(word: word, flipped: $flipped, dragOffset: dragOffset)
                        .offset(dragOffset)
                        .rotationEffect(.degrees(Double(dragOffset.width / 18)))
                        .gesture(dragGesture)
                        .onTapGesture {
                            guard !isSwipingOut else { return }
                            Haptics.tap()
                            SoundFX.swipe()
                            flipped.toggle()
                        }
                        .id(word.persistentModelID)
                        .transition(.asymmetric(insertion: .scale(scale: 0.92).combined(with: .opacity), removal: .identity))
                        .onAppear {
                            if autoPlay {
                                SpeechService.shared.speak(word.english)
                            }
                        }
                }
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)

            swipeHints
            actionButtons
                .padding(.bottom, 16)
        }
        .padding(.top, 8)
    }

    private var progressHeader: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(gradedCount) / \(sessionTotal)")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 12) {
                    Label("\(knownCount)", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Label("\(forgotCount)", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
                .font(.subheadline.monospacedDigit())
            }
            ProgressView(value: Double(gradedCount), total: Double(max(1, sessionTotal)))
                .tint(LinearGradient.brand)
        }
        .padding(.horizontal, 24)
    }

    private var swipeHints: some View {
        HStack(spacing: 18) {
            Label("左滑 不认识", systemImage: "arrow.left")
                .foregroundStyle(.red.opacity(0.8))
            Label("上滑 收藏", systemImage: "arrow.up")
                .foregroundStyle(.orange.opacity(0.9))
            Label("右滑 认识", systemImage: "arrow.right")
                .foregroundStyle(.green.opacity(0.8))
        }
        .font(.caption2)
    }

    private var actionButtons: some View {
        HStack(spacing: 36) {
            CardActionButton(icon: "xmark", color: .red) {
                programmaticSwipe(.forgot)
            }
            .accessibilityLabel("不认识")
            CardActionButton(icon: "star.fill", color: .orange, small: true) {
                programmaticSwipe(.favorite)
            }
            .accessibilityLabel("收藏")
            CardActionButton(icon: "checkmark", color: .green) {
                programmaticSwipe(.known)
            }
            .accessibilityLabel("认识")
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: mode == .review ? "checkmark.circle.fill" : "books.vertical.fill",
            title: mode == .review ? "暂无待复习单词" : "词库已全部学完",
            message: mode == .review
                ? "当前没有到期的单词，先去学点新词吧"
                : "恭喜你学完了全部预置单词！可在设置中重置进度重新开始",
            actionTitle: "返回",
            action: { dismiss() }
        )
    }

    // MARK: - 手势

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isSwipingOut else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                guard !isSwipingOut else { return }
                let t = value.translation
                if t.width > 110 {
                    swipeOut(.known)
                } else if t.width < -110 {
                    swipeOut(.forgot)
                } else if t.height < -110 && abs(t.width) < 90 {
                    swipeOut(.favorite)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    private func programmaticSwipe(_ grade: ReviewGrade) {
        guard !isSwipingOut, queue.first != nil else { return }
        swipeOut(grade)
    }

    /// 卡片飞出动画 → 评分落库 → 下一张
    private func swipeOut(_ grade: ReviewGrade) {
        guard let word = queue.first else { return }
        isSwipingOut = true

        switch grade {
        case .known:
            Haptics.success()
            SoundFX.correct()
        case .forgot:
            Haptics.error()
            SoundFX.wrong()
        case .favorite:
            Haptics.medium()
            SoundFX.swipe()
        }

        let target: CGSize = switch grade {
        case .known: CGSize(width: 600, height: dragOffset.height)
        case .forgot: CGSize(width: -600, height: dragOffset.height)
        case .favorite: CGSize(width: dragOffset.width, height: -900)
        }

        withAnimation(.easeIn(duration: 0.28)) {
            dragOffset = target
        }

        StudyService.grade(word, grade: grade, context: modelContext)
        switch grade {
        case .known: knownCount += 1
        case .forgot: forgotCount += 1
        case .favorite: favoriteCount += 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            flipped = false
            dragOffset = .zero
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                if !queue.isEmpty { queue.removeFirst() }
            }
            isSwipingOut = false
            if queue.isEmpty {
                finishSession()
            }
        }
    }

    // MARK: - 会话生命周期

    private func loadIfNeeded() {
        guard !loaded else { return }
        loadBatch()
        loaded = true
    }

    private func loadBatch() {
        let words: [Word] = switch mode {
        case .newWords:
            StudyService.newWordsBatch(context: modelContext, dailyGoal: dailyGoal)
        case .review:
            StudyService.dueWords(context: modelContext)
        }
        queue = words
        sessionTotal = words.count
        knownCount = 0
        forgotCount = 0
        favoriteCount = 0
    }

    private func finishSession() {
        SoundFX.complete()
        Haptics.success()
        let newly = AchievementEngine.evaluate(context: modelContext)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            showSummary = true
            celebrationQueue = newly
        }
    }

    private var summaryOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            SessionSummaryCard(
                known: knownCount,
                forgot: forgotCount,
                favorited: favoriteCount,
                onContinue: {
                    withAnimation { showSummary = false }
                    loadBatch()
                    if sessionTotal == 0 {
                        dismiss()
                    }
                },
                onDone: { dismiss() }
            )
            .padding(.horizontal, 36)
        }
        .transition(.opacity)
        .zIndex(5)
    }
}

// MARK: - 单词卡（正反 3D 翻转 + 滑动反馈）

struct WordCardView: View {
    let word: Word
    @Binding var flipped: Bool
    var dragOffset: CGSize = .zero

    private var rightProgress: Double { max(0, min(1, Double(dragOffset.width) / 130)) }
    private var leftProgress: Double { max(0, min(1, Double(-dragOffset.width) / 130)) }
    private var upProgress: Double {
        guard abs(dragOffset.width) < 90 else { return 0 }
        return max(0, min(1, Double(-dragOffset.height) / 130))
    }

    var body: some View {
        ZStack {
            cardFace { frontContent }
                .opacity(flipped ? 0 : 1)
                .rotation3DEffect(.degrees(flipped ? -180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.55)
            cardFace { backContent }
                .opacity(flipped ? 1 : 0)
                .rotation3DEffect(.degrees(flipped ? 0 : 180), axis: (x: 0, y: 1, z: 0), perspective: 0.55)
        }
        .animation(.spring(response: 0.48, dampingFraction: 0.78), value: flipped)
        .overlay { feedbackOverlay }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.72, contentMode: .fit)
    }

    private func cardFace<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
            .shadow(color: .black.opacity(0.10), radius: 12, y: 6)
            .overlay(content())
    }

    private var frontContent: some View {
        VStack(spacing: 14) {
            categoryTag
            Spacer()
            Text(word.english)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.horizontal, 18)
            Text(word.phonetic)
                .font(.title3)
                .foregroundStyle(.secondary)
            speakerButton(text: word.english)
            Spacer()
            Text("点击卡片查看释义")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 18)
        }
        .padding(.top, 18)
    }

    private var backContent: some View {
        VStack(spacing: 12) {
            categoryTag
            Spacer(minLength: 6)
            HStack(spacing: 8) {
                Text(word.english)
                    .font(.title2.bold())
                speakerButton(text: word.english, compact: true)
            }
            Text(word.meaning)
                .font(.title3.bold())
                .foregroundStyle(Color.brandPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            Divider().padding(.horizontal, 28)

            VStack(spacing: 8) {
                Text(word.example)
                    .font(.callout.italic())
                    .multilineTextAlignment(.center)
                Text(word.exampleTranslation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                speakerButton(text: word.example, compact: true)
            }
            .padding(.horizontal, 18)
            Spacer(minLength: 6)
            Text("点击卡片返回正面")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 18)
        }
        .padding(.top, 18)
    }

    private var categoryTag: some View {
        HStack {
            Text(word.category.displayName)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(word.category == .cet4 ? Color.brandPrimary : Color.brandSecondary))
            Spacer()
            if word.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 18)
    }

    private func speakerButton(text: String, compact: Bool = false) -> some View {
        Button {
            Haptics.tap()
            SpeechService.shared.speak(text)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(compact ? .body : .title2)
                .foregroundStyle(Color.brandPrimary)
                .padding(compact ? 6 : 12)
                .background(Circle().fill(Color.brandPrimary.opacity(0.12)))
        }
        .buttonStyle(.plain)
    }

    /// 滑动方向的颜色渐变 + 印章反馈
    private var feedbackOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.green.opacity(rightProgress * 0.22))
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.red.opacity(leftProgress * 0.22))
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.orange.opacity(upProgress * 0.22))

            GradeStamp(text: "认识", color: .green)
                .opacity(rightProgress)
                .rotationEffect(.degrees(-14))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(22)
            GradeStamp(text: "不认识", color: .red)
                .opacity(leftProgress)
                .rotationEffect(.degrees(14))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(22)
            GradeStamp(text: "★ 收藏", color: .orange)
                .opacity(upProgress)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(28)
        }
        .allowsHitTesting(false)
    }
}

struct GradeStamp: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.title2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color, lineWidth: 3.5)
            )
    }
}

struct CardActionButton: View {
    let icon: String
    let color: Color
    var small: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: small ? 22 : 26, weight: .bold))
                .foregroundStyle(color)
                .frame(width: small ? 56 : 66, height: small ? 56 : 66)
                .background(
                    Circle()
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(color: color.opacity(0.35), radius: 8, y: 3)
                )
                .overlay(Circle().stroke(color.opacity(0.4), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 本轮统计弹窗

struct SessionSummaryCard: View {
    let known: Int
    let forgot: Int
    let favorited: Int
    let onContinue: () -> Void
    let onDone: () -> Void

    private var total: Int { known + forgot + favorited }
    private var accuracy: Double {
        total == 0 ? 0 : Double(known + favorited) / Double(total)
    }

    var body: some View {
        VStack(spacing: 18) {
            Text("本轮学习完成 🎉")
                .font(.title3.bold())

            ZStack {
                ProgressRing(progress: accuracy, lineWidth: 10)
                    .frame(width: 110, height: 110)
                VStack(spacing: 0) {
                    Text("\(Int((accuracy * 100).rounded()))%")
                        .font(.title2.bold().monospacedDigit())
                    Text("认识率")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 14) {
                summaryStat(value: known, label: "认识", color: .green)
                summaryStat(value: forgot, label: "不认识", color: .red)
                summaryStat(value: favorited, label: "收藏", color: .orange)
            }

            VStack(spacing: 10) {
                Button {
                    Haptics.medium()
                    onContinue()
                } label: {
                    Text("再来一组")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: 14).fill(LinearGradient.brand))
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.tap()
                    onDone()
                } label: {
                    Text("完成")
                        .font(.headline)
                        .foregroundStyle(Color.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func summaryStat(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 64)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.1)))
    }
}
