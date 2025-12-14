//
//  NotificationService.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    private let notificationIdentifier = "daily_reminder"

    private init() {}

    /// Request notification permission from user
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }

    /// Schedule a daily repeating notification at the specified time
    func scheduleDaily(at time: Date) async {
        // First, cancel any existing notifications
        cancelAll()

        // Extract hour and minute from the date
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "LingoLearn"
        content.body = "该学习单词了！保持每日学习习惯"
        content.sound = .default
        content.badge = 1

        // Create trigger for daily repeating notification
        var dateComponents = DateComponents()
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Create request
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )

        // Add notification request
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Daily notification scheduled for \(components.hour ?? 0):\(components.minute ?? 0)")
        } catch {
            print("Error scheduling notification: \(error)")
        }
    }

    /// Cancel all pending notifications
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    /// Check current notification settings
    func checkSettings() async -> UNNotificationSettings {
        return await UNUserNotificationCenter.current().notificationSettings()
    }

    /// Send an immediate notification (for testing or achievement unlocks)
    func sendImmediateNotification(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error sending immediate notification: \(error)")
        }
    }
}
