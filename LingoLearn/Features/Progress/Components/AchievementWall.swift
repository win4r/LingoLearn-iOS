//
//  AchievementWall.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI

struct AchievementWall: View {
    let unlockedAchievements: [String]
    let onAchievementTap: (Achievement) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Achievement.all) { achievement in
                AchievementBadge(
                    achievement: achievement,
                    isUnlocked: unlockedAchievements.contains(achievement.id)
                )
                .onTapGesture {
                    onAchievementTap(achievement)
                }
            }
        }
    }
}

struct AchievementBadge: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                    .frame(width: 60, height: 60)

                if isUnlocked {
                    Image(systemName: achievement.iconName)
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            Text(achievement.title)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(isUnlocked ? .primary : .secondary)
                .lineLimit(2)
        }
    }
}

#Preview {
    AchievementWall(
        unlockedAchievements: ["first_word", "streak_7"],
        onAchievementTap: { _ in }
    )
    .padding()
}
