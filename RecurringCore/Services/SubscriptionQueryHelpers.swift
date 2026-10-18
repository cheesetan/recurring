//
//  SubscriptionQueryHelpers.swift
//  recurring
//

import Foundation
import SwiftData

enum SubscriptionQueryHelpers {
    static func allSnapshots(_ subscriptions: [Subscription]) -> [SubscriptionSnapshot] {
        subscriptions.map { sub in
            sub.snapshot()
        }
    }

    static func useMap(_ subscriptions: [Subscription]) -> [UUID: SubscriptionUse] {
        Dictionary(uniqueKeysWithValues: subscriptions.map { ($0.id, $0.use) })
    }

    static func allChargeLines(_ subscriptions: [Subscription]) -> [ChargeLine] {
        subscriptions.flatMap { $0.chargeLines() }
    }

    static func upcomingSubscriptions(
        _ subscriptions: [Subscription],
        showCancelled: Bool,
        useFilter: UseFilter,
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> [Subscription] {
        subscriptions
            .filter { sub in
                if sub.state == .cancelled {
                    return showCancelled && useFilter.matches(sub.use)
                }
                return useFilter.matches(sub.use)
            }
            .sorted { $0.renewalDate < $1.renewalDate }
    }

    static func renewalsOnDay(
        _ subscriptions: [Subscription],
        day: Date,
        useFilter: UseFilter,
        calendar: Calendar = .current
    ) -> [(Subscription, Decimal)] {
        let dayStart = calendar.startOfDay(for: day)
        var result: [(Subscription, Decimal)] = []
        for sub in subscriptions where sub.state != .cancelled && useFilter.matches(sub.use) {
            let snap = sub.snapshot()
            for date in SpendEngine.nextChargeDates(for: snap, from: dayStart, limit: 1, calendar: calendar) {
                if calendar.isDate(date, inSameDayAs: dayStart) {
                    result.append((sub, sub.sgdAmount))
                }
            }
        }
        return result
    }
}
