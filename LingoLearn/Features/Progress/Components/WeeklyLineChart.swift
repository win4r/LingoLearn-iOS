//
//  WeeklyLineChart.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI
import Charts

struct WeeklyLineChart: View {
    let data: [(date: Date, count: Int)]

    var body: some View {
        Chart(data, id: \.date) { item in
            LineMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Words", item.count)
            )
            .foregroundStyle(Color.accentColor.gradient)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Words", item.count)
            )
            .foregroundStyle(Color.accentColor.opacity(0.1).gradient)
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.weekday(.abbreviated))
                    }
                    AxisGridLine()
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel()
                AxisGridLine()
            }
        }
    }
}

#Preview {
    let calendar = Calendar.current
    let today = Date()
    let sampleData = (0..<7).map { day in
        let date = calendar.date(byAdding: .day, value: -day, to: today)!
        return (date: date, count: Int.random(in: 5...30))
    }.reversed()

    return WeeklyLineChart(data: Array(sampleData))
        .frame(height: 200)
        .padding()
}
