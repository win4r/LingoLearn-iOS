//
//  MasteryPieChart.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI
import Charts

struct MasteryPieChart: View {
    let newCount: Int
    let learningCount: Int
    let reviewingCount: Int
    let masteredCount: Int

    private var total: Int {
        newCount + learningCount + reviewingCount + masteredCount
    }

    var body: some View {
        if total == 0 {
            // Empty state
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .overlay(
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )

                VStack {
                    Image(systemName: "book.closed")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("暂无数据")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            Chart {
                if newCount > 0 {
                    SectorMark(
                        angle: .value("Count", newCount),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(.gray)
                }

                if learningCount > 0 {
                    SectorMark(
                        angle: .value("Count", learningCount),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(.orange)
                }

                if reviewingCount > 0 {
                    SectorMark(
                        angle: .value("Count", reviewingCount),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(.blue)
                }

                if masteredCount > 0 {
                    SectorMark(
                        angle: .value("Count", masteredCount),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(.green)
                }
            }
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    let frame = geometry[chartProxy.plotFrame!]
                    VStack {
                        Text("\(total)")
                            .font(.title.bold())
                        Text("总词汇")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .position(x: frame.midX, y: frame.midY)
                }
            }
        }
    }
}

#Preview {
    MasteryPieChart(
        newCount: 50,
        learningCount: 30,
        reviewingCount: 15,
        masteredCount: 20
    )
    .frame(height: 200)
    .padding()
}
