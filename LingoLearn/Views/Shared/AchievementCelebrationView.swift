//
//  AchievementCelebrationView.swift
//  LingoLearn
//
//  成就解锁庆祝弹层（徽章弹跳 + 彩带）。
//

import SwiftUI

struct AchievementCelebrationView: View {
    let kind: AchievementKind
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            ConfettiView()
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.brand)
                        .frame(width: 110, height: 110)
                        .shadow(color: Color.brandPrimary.opacity(0.5), radius: 18)
                    Image(systemName: kind.icon)
                        .font(.system(size: 48))
                        .foregroundStyle(.white)
                }
                .scaleEffect(appeared ? 1 : 0.2)
                .rotationEffect(.degrees(appeared ? 0 : -30))

                Text("成就解锁！")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
                Text(kind.title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text(kind.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))

                Button {
                    Haptics.tap()
                    onDismiss()
                } label: {
                    Text("太棒了")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 44)
                        .padding(.vertical, 13)
                        .background(Capsule().fill(LinearGradient.brand))
                }
                .padding(.top, 10)
            }
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            Haptics.success()
            SoundFX.complete()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.62)) {
                appeared = true
            }
        }
    }
}
