//
//  FlameStreakView.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI

struct FlameStreakView: View {
    let streakCount: Int
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 28))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6).repeatCount(1), value: isAnimating)

            Text("\(streakCount)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            Text("天")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
        .onChange(of: streakCount) { oldValue, newValue in
            if newValue > oldValue {
                isAnimating = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isAnimating = false
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        FlameStreakView(streakCount: 7)
        FlameStreakView(streakCount: 30)
        FlameStreakView(streakCount: 100)
    }
    .padding()
}
