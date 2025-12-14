//
//  AchievementUnlockAnimation.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI

struct AchievementUnlockAnimation: View {
    let achievement: Achievement
    @Binding var isPresented: Bool

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = -15
    @State private var confettiTrigger: Bool = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Achievement card
            VStack(spacing: 20) {
                // Badge icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: achievement.iconName)
                        .font(.system(size: 50))
                        .foregroundStyle(Color.accentColor)
                }
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))

                VStack(spacing: 8) {
                    Text("解锁成就!")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text(achievement.title)
                        .font(.title2.bold())

                    Text(achievement.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(opacity)

                Button(action: dismiss) {
                    Text("太棒了!")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding(.top)
                .opacity(opacity)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.3), radius: 20)
            )
            .padding(40)

            // Confetti overlay
            if confettiTrigger {
                ConfettiView()
            }
        }
        .onAppear {
            playAnimation()
        }
    }

    private func playAnimation() {
        // Icon animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            scale = 1.0
            rotation = 0
        }

        // Content fade in
        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            opacity = 1.0
        }

        // Confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            confettiTrigger = true
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0
            scale = 0.8
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}

struct ConfettiView: View {
    @State private var animate = false
    private let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]

    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<50, id: \.self) { index in
                Circle()
                    .fill(colors.randomElement() ?? .blue)
                    .frame(width: 10, height: 10)
                    .position(
                        x: animate ? CGFloat.random(in: 0...geometry.size.width) : geometry.size.width / 2,
                        y: animate ? geometry.size.height + 50 : 100
                    )
                    .opacity(animate ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2.0)) {
                animate = true
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    AchievementUnlockAnimation(
        achievement: Achievement.all[0],
        isPresented: .constant(true)
    )
}
