//
//  FlashcardItem.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI

struct FlashcardItem: View {
    let word: Word
    let onSwipe: (SwipeDirection) -> Void

    @State private var isFlipped = false
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    private let speechService = SpeechService.shared

    private let swipeThreshold: CGFloat = 100

    var body: some View {
        ZStack {
            // Card Back (Chinese side)
            cardBack
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : 180),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(isFlipped ? 1 : 0)

            // Card Front (English side)
            cardFront
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(isFlipped ? 0 : 1)
        }
        .frame(width: 320, height: 450)
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .overlay(swipeOverlay)
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation
                    rotation = Double(value.translation.width / 20)
                }
                .onEnded { value in
                    handleSwipeEnd(value: value)
                }
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
    }

    private var cardFront: some View {
        VStack(spacing: 20) {
            Spacer()

            // Word
            Text(word.english)
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.primary)

            // Phonetic
            Text(word.phonetic)
                .font(.system(size: 20))
                .foregroundColor(.secondary)

            // Part of Speech
            Text(word.partOfSpeech)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.7))
                .cornerRadius(12)

            Spacer()

            // Speaker Button
            Button(action: {
                speechService.speak(text: word.english, language: "en-US")
            }) {
                Image(systemName: speechService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 50, height: 50)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(25)
            }

            Text("点击翻转查看释义")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
        }
        .padding()
        .frame(width: 320, height: 450)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color.blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 5)
    }

    private var cardBack: some View {
        VStack(spacing: 16) {
            Spacer()

            // Chinese Meaning
            Text(word.chinese)
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Divider()
                .frame(width: 200)
                .padding(.vertical, 8)

            // Example Sentence
            VStack(spacing: 8) {
                Text("例句")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(word.exampleSentence)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text(word.exampleTranslation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)

            Spacer()

            // Mastery Level Badge
            HStack(spacing: 12) {
                MasteryBadge(level: word.masteryLevel)

                if word.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.yellow)
                }
            }
            .padding(.bottom, 8)
        }
        .padding()
        .frame(width: 320, height: 450)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color.purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 5)
    }

    private var swipeOverlay: some View {
        Group {
            if offset.width > 50 {
                // Right swipe - Know it
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.green.opacity(0.3))
                    .overlay(
                        VStack {
                            Image(systemName: "hand.thumbsup.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.green)
                            Text("认识")
                                .font(.title)
                                .foregroundColor(.green)
                        }
                    )
            } else if offset.width < -50 {
                // Left swipe - Don't know
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.red.opacity(0.3))
                    .overlay(
                        VStack {
                            Image(systemName: "hand.thumbsdown.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.red)
                            Text("不认识")
                                .font(.title)
                                .foregroundColor(.red)
                        }
                    )
            } else if offset.height < -50 {
                // Up swipe - Favorite
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.yellow.opacity(0.3))
                    .overlay(
                        VStack {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.yellow)
                            Text("收藏")
                                .font(.title)
                                .foregroundColor(.yellow)
                        }
                    )
            }
        }
    }

    private func handleSwipeEnd(value: DragGesture.Value) {
        let horizontalAmount = value.translation.width
        let verticalAmount = value.translation.height

        if abs(horizontalAmount) > abs(verticalAmount) {
            // Horizontal swipe
            if horizontalAmount > swipeThreshold {
                // Right swipe - Know it
                withAnimation {
                    offset = CGSize(width: 500, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onSwipe(.right)
                    resetCard()
                }
            } else if horizontalAmount < -swipeThreshold {
                // Left swipe - Don't know
                withAnimation {
                    offset = CGSize(width: -500, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onSwipe(.left)
                    resetCard()
                }
            } else {
                resetCard()
            }
        } else {
            // Vertical swipe
            if verticalAmount < -swipeThreshold {
                // Up swipe - Favorite
                withAnimation {
                    offset = CGSize(width: 0, height: -500)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onSwipe(.up)
                    resetCard()
                }
            } else {
                resetCard()
            }
        }
    }

    private func resetCard() {
        withAnimation(.spring()) {
            offset = .zero
            rotation = 0
            isFlipped = false
        }
    }
}

struct MasteryBadge: View {
    let level: MasteryLevel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption)

            Text(level.rawValue)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .cornerRadius(12)
    }

    private var backgroundColor: Color {
        switch level {
        case .new:
            return .gray
        case .learning:
            return .orange
        case .reviewing:
            return .blue
        case .mastered:
            return .green
        }
    }
}

#Preview {
    FlashcardItem(
        word: Word(
            english: "Hello",
            chinese: "你好",
            phonetic: "/həˈloʊ/",
            partOfSpeech: "noun",
            exampleSentence: "Hello, how are you?",
            exampleTranslation: "你好,你好吗?",
            category: .cet4,
            difficulty: 1
        ),
        onSwipe: { _ in }
    )
}
