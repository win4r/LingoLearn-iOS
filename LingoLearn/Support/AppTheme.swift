//
//  AppTheme.swift
//  LingoLearn
//

import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    /// 主色调 #0EA5E9
    static let brandPrimary = Color(hex: 0x0EA5E9)
    /// 辅助色 #14B8A6
    static let brandSecondary = Color(hex: 0x14B8A6)
}

extension LinearGradient {
    static let brand = LinearGradient(
        colors: [.brandPrimary, .brandSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    /// 通用卡片底板样式（自动适配深浅色）
    func cardSurface(cornerRadius: CGFloat = 20) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
    }
}
