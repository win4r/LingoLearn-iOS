//
//  CountdownTimerBar.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI

struct CountdownTimerBar: View {
    let timeRemaining: Double
    let totalTime: Double
    @State private var shouldPulse = false

    private var progress: Double {
        guard totalTime > 0 else { return 0 }
        return timeRemaining / totalTime
    }

    private var barColor: Color {
        if progress > 0.5 {
            return .green
        } else if progress > 0.2 {
            return .yellow
        } else {
            return .red
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))

                Rectangle()
                    .fill(barColor)
                    .frame(width: geometry.size.width * progress)
                    .animation(.linear(duration: 0.1), value: progress)
            }
        }
        .frame(height: 6)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .scaleEffect(shouldPulse ? 1.05 : 1.0)
        .onChange(of: timeRemaining) { oldValue, newValue in
            if newValue <= 3 && newValue > 0 {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    shouldPulse = true
                }
            } else {
                shouldPulse = false
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CountdownTimerBar(timeRemaining: 15, totalTime: 15)
        CountdownTimerBar(timeRemaining: 7, totalTime: 15)
        CountdownTimerBar(timeRemaining: 2, totalTime: 15)
    }
    .padding()
}
