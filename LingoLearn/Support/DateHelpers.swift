//
//  DateHelpers.swift
//  LingoLearn
//

import Foundation

extension Calendar {
    /// 两个日期相隔的自然天数（按 startOfDay 计算）
    func dayDistance(from: Date, to: Date) -> Int {
        let f = startOfDay(for: from)
        let t = startOfDay(for: to)
        return dateComponents([.day], from: f, to: t).day ?? 0
    }
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}
