//
//  CalendarHeatmap.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI

struct CalendarHeatmap: View {
    let dailyProgress: [DailyProgress]
    @State private var selectedMonth: Date = Date()

    private let calendar = Calendar.current
    private let weekdayLabels = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        VStack(spacing: 12) {
            // Month Navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Text(selectedMonth, format: .dateTime.year().month(.wide))
                    .font(.headline)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                }
                .disabled(calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month))
            }

            // Heatmap Grid
            VStack(spacing: 4) {
                // Weekday headers
                HStack(spacing: 4) {
                    ForEach(weekdayLabels, id: \.self) { label in
                        Text(label)
                            .font(.caption2)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.secondary)
                    }
                }

                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                    ForEach(daysInMonth, id: \.self) { date in
                        if let date = date {
                            DayCell(
                                date: date,
                                intensity: intensityForDate(date)
                            )
                        } else {
                            Color.clear
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
    }

    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let numberOfDays = calendar.range(of: .day, in: .month, for: selectedMonth)?.count ?? 0

        var days: [Date?] = []

        // Add empty cells for days before the first day of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }

        // Add days of the month
        for day in 0..<numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day, to: monthInterval.start) {
                days.append(date)
            }
        }

        return days
    }

    private func intensityForDate(_ date: Date) -> Double {
        guard let progress = dailyProgress.first(where: {
            calendar.isDate($0.date, inSameDayAs: date)
        }) else {
            return 0
        }

        let wordsLearned = progress.wordsLearned
        if wordsLearned == 0 { return 0 }
        if wordsLearned < 5 { return 0.25 }
        if wordsLearned < 10 { return 0.5 }
        if wordsLearned < 20 { return 0.75 }
        return 1.0
    }

    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newDate
        }
    }

    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedMonth),
           newDate <= Date() {
            selectedMonth = newDate
        }
    }
}

struct DayCell: View {
    let date: Date
    let intensity: Double

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var backgroundColor: Color {
        if intensity == 0 {
            return Color(.systemGray6)
        }
        return Color.accentColor.opacity(intensity)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)

            if isToday {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
            }

            Text("\(Calendar.current.component(.day, from: date))")
                .font(.caption2)
                .foregroundStyle(intensity > 0.5 ? .white : .primary)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    CalendarHeatmap(dailyProgress: [])
        .padding()
}
