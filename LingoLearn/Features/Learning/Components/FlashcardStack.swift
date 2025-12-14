//
//  FlashcardStack.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI

struct FlashcardStack: View {
    let words: [Word]
    let currentIndex: Int
    let onSwipe: (SwipeDirection) -> Void

    private let maxVisibleCards = 3
    private let cardOffset: CGFloat = 8
    private let cardScale: CGFloat = 0.05

    var body: some View {
        ZStack {
            ForEach(visibleCardIndices, id: \.self) { index in
                if index < words.count {
                    FlashcardItem(
                        word: words[index],
                        onSwipe: onSwipe
                    )
                    .offset(y: offsetForCard(at: index))
                    .scaleEffect(scaleForCard(at: index))
                    .zIndex(zIndexForCard(at: index))
                    .allowsHitTesting(index == currentIndex)
                }
            }
        }
        .frame(height: 500)
    }

    private var visibleCardIndices: [Int] {
        let start = currentIndex
        let end = min(currentIndex + maxVisibleCards, words.count)
        return Array(start..<end)
    }

    private func offsetForCard(at index: Int) -> CGFloat {
        let position = index - currentIndex
        return CGFloat(position) * cardOffset
    }

    private func scaleForCard(at index: Int) -> CGFloat {
        let position = index - currentIndex
        return 1.0 - (CGFloat(position) * cardScale)
    }

    private func zIndexForCard(at index: Int) -> Double {
        return Double(words.count - index)
    }
}

#Preview {
    FlashcardStack(
        words: [
            Word(
                english: "Hello",
                chinese: "你好",
                phonetic: "/həˈloʊ/",
                partOfSpeech: "noun",
                exampleSentence: "Hello, how are you?",
                exampleTranslation: "你好,你好吗?",
                category: .cet4,
                difficulty: 1
            ),
            Word(
                english: "Goodbye",
                chinese: "再见",
                phonetic: "/ɡʊdˈbaɪ/",
                partOfSpeech: "noun",
                exampleSentence: "Goodbye, see you tomorrow.",
                exampleTranslation: "再见,明天见。",
                category: .cet4,
                difficulty: 1
            ),
            Word(
                english: "Thank you",
                chinese: "谢谢",
                phonetic: "/θæŋk juː/",
                partOfSpeech: "phrase",
                exampleSentence: "Thank you for your help.",
                exampleTranslation: "谢谢你的帮助。",
                category: .cet4,
                difficulty: 1
            )
        ],
        currentIndex: 0,
        onSwipe: { _ in }
    )
}
