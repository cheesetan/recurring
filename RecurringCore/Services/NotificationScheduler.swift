//
//  NotificationScheduler.swift
//  recurring
//

import Foundation
import SwiftData
import UserNotifications

enum NotificationScheduler {
    static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }
    }

    static func rescheduleAll(context: ModelContext) async {
        guard UserDefaults.standard.bool(forKey: AppConstants.notificationsEnabledKey) else {
            await clearAll()
            return
        }

        let calendar = Calendar.current
        let subs: [Subscription]
        do {
            subs = try context.fetch(FetchDescriptor<Subscription>())
        } catch {
            return
        }

        await clearAll()

        for sub in subs where sub.state != .cancelled {
            guard let fireDate = notificationFireDate(for: sub, calendar: calendar) else { continue }
            let content = UNMutableNotificationContent()
            content.title = sub.name
            content.body = "Renews \(sub.renewalDate.formatted(date: .abbreviated, time: .omitted)) · \(sub.sgdAmount.formatted(.currency(code: "SGD")))"
            content.sound = .default

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: sub.id.uuidString,
                content: content,
                trigger: trigger
            )
            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    static func notificationFireDate(for sub: Subscription, calendar: Calendar = .current) -> Date? {
        let renewalDay = calendar.startOfDay(for: sub.renewalDate)
        guard renewalDay >= calendar.startOfDay(for: Date()) else { return nil }
        guard let lead = calendar.date(byAdding: .day, value: -sub.leadTimeDays, to: renewalDay) else { return nil }
        var components = calendar.dateComponents([.year, .month, .day], from: lead)
        components.hour = AppConstants.notificationHour
        components.minute = 0
        guard let fire = calendar.date(from: components) else { return nil }
        if fire < Date() {
            var sameDay = calendar.dateComponents([.year, .month, .day], from: Date())
            sameDay.hour = AppConstants.notificationHour
            sameDay.minute = 0
            return calendar.date(from: sameDay)
        }
        return fire
    }

    static func clearAll() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier))
    }
}
