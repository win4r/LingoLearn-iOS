//
//  DailyGoalSlider.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI

struct DailyGoalSlider: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int

    var body: some View {
        VStack(spacing: 16) {
            // Current value display
            HStack {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundStyle(.orange)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(value)")
                            .font(.system(size: 36, weight: .bold))
                        Text("个单词/天")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )

            // Slider
            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { Double(value) },
                        set: { value = Int($0 / Double(step)) * step }
                    ),
                    in: Double(range.lowerBound)...Double(range.upperBound),
                    step: Double(step)
                )
                .tint(.orange)

                // Range labels
                HStack {
                    Text("\(range.lowerBound)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(range.upperBound)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    DailyGoalSlider(
        value: .constant(20),
        range: 10...100,
        step: 5
    )
    .padding()
}
