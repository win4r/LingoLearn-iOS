//
//  RingProgressView.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI

struct RingProgressView: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let gradientColors: [Color]
    let size: CGFloat

    @State private var animatedProgress: Double = 0

    init(progress: Double, lineWidth: CGFloat = 20, gradientColors: [Color] = [.blue, .purple], size: CGFloat = 150) {
        self.progress = min(max(progress, 0), 1) // Clamp between 0 and 1
        self.lineWidth = lineWidth
        self.gradientColors = gradientColors
        self.size = size
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

            // Progress circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradientColors),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * animatedProgress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animatedProgress)

            // Center content
            VStack(spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.2, weight: .bold))
                Text("完成")
                    .font(.system(size: size * 0.1))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { oldValue, newValue in
            animatedProgress = newValue
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        RingProgressView(progress: 0.65)
        RingProgressView(progress: 0.30, gradientColors: [.green, .blue])
        RingProgressView(progress: 0.90, gradientColors: [.orange, .red])
    }
}
