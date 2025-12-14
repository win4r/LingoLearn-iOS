//
//  SessionSummarySheet.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI

struct SessionSummarySheet: View {
    let stats: SessionStats
    let onContinue: () -> Void
    let onHome: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Success Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                    .padding(.top, 40)

                // Title
                Text("学习完成!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Stats Cards
                VStack(spacing: 16) {
                    SessionStatCard(
                        icon: "book.fill",
                        title: "学习单词",
                        value: "\(stats.totalReviewed)",
                        color: .blue
                    )

                    HStack(spacing: 16) {
                        SessionStatCard(
                            icon: "checkmark.circle.fill",
                            title: "认识",
                            value: "\(stats.knownCount)",
                            color: .green
                        )

                        SessionStatCard(
                            icon: "xmark.circle.fill",
                            title: "不认识",
                            value: "\(stats.unknownCount)",
                            color: .red
                        )
                    }

                    SessionStatCard(
                        icon: "chart.bar.fill",
                        title: "准确率",
                        value: String(format: "%.0f%%", stats.accuracy * 100),
                        color: stats.accuracy >= 0.7 ? .green : .orange
                    )
                }
                .padding(.horizontal)

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        dismiss()
                        onContinue()
                    }) {
                        Text("继续学习")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        dismiss()
                        onHome()
                    }) {
                        Text("返回首页")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("学习总结")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

struct SessionStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    SessionSummarySheet(
        stats: SessionStats(totalReviewed: 20, knownCount: 15, unknownCount: 5),
        onContinue: {},
        onHome: {}
    )
}
