//
//  NotificationManager.swift
//  LingoLearn
//
//  每日学习提醒（本地通知）。
//

import Foundation
import UserNotifications

enum NotificationManager {
    static let reminderIdentifier = "lingolearn.daily.reminder"

    /// 申请通知权限；返回是否可用
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        @unknown default:
            return false
        }
    }

    /// 设定每天固定时间的提醒（分钟数 = 距 0 点的偏移）
    static func scheduleDaily(minutesFromMidnight: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "LingoLearn 学习提醒"
        content.body = "今天的单词还在等你，保持连续打卡 🔥"
        content.sound = .default

        var components = DateComponents()
        components.hour = minutesFromMidnight / 60
        components.minute = minutesFromMidnight % 60

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: reminderIdentifier,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    static func cancelDaily() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
    }
}
