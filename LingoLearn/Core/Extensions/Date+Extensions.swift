import Foundation

extension Date {
    // Get start of day for current date
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    // Check if date is today
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }

    // Check if date is yesterday
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }

    // Get date N days ago
    func daysAgo(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }
}
