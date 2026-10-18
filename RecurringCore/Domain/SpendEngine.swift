//
//  SpendEngine.swift
//  recurring
//

import Foundation

struct ChargeLine: Equatable {
    var id: UUID
    var subscriptionID: UUID
    var date: Date
    var sgdAmount: Decimal
    var isConfirmed: Bool
}

struct SubscriptionSnapshot: Equatable {
    var id: UUID
    var name: String
    var state: SubscriptionState
    var use: SubscriptionUse
    var renewalDate: Date
    var paidThrough: Date?
    var cadence: Cadence
    var sgdAmount: Decimal
    var leadTimeDays: Int
}

enum SpendEngine {
    static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    // MARK: - Cash

    static func cash(
        charges: [ChargeLine],
        subscriptionUses: [UUID: SubscriptionUse],
        useFilter: UseFilter,
        from: Date,
        through: Date,
        calendar: Calendar = .current
    ) -> Decimal {
        let fromDay = startOfDay(from, calendar: calendar)
        let throughDay = startOfDay(through, calendar: calendar)
        return charges
            .filter(\.isConfirmed)
            .filter { charge in
                let day = startOfDay(charge.date, calendar: calendar)
                guard day >= fromDay, day <= throughDay else { return false }
                guard let use = subscriptionUses[charge.subscriptionID] else { return false }
                return useFilter.matches(use)
            }
            .reduce(Decimal.zero) { $0 + $1.sgdAmount }
    }

    static func cashByMonth(
        charges: [ChargeLine],
        subscriptionUses: [UUID: SubscriptionUse],
        useFilter: UseFilter,
        from: Date,
        through: Date,
        calendar: Calendar = .current
    ) -> [(monthStart: Date, total: Decimal)] {
        let fromDay = startOfDay(from, calendar: calendar)
        let throughDay = startOfDay(through, calendar: calendar)
        var buckets: [Date: Decimal] = [:]

        for charge in charges where charge.isConfirmed {
            let day = startOfDay(charge.date, calendar: calendar)
            guard day >= fromDay, day <= throughDay else { continue }
            guard let use = subscriptionUses[charge.subscriptionID], useFilter.matches(use) else { continue }
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: day)) ?? day
            buckets[monthStart, default: 0] += charge.sgdAmount
        }

        return buckets.keys.sorted().map { ($0, buckets[$0] ?? 0) }
    }

    // MARK: - Run rate

    static func runRate(
        subscriptions: [SubscriptionSnapshot],
        useFilter: UseFilter
    ) -> Decimal {
        subscriptions
            .filter { sub in useFilter.matches(sub.use) && countsTowardRunRate(sub) }
            .reduce(Decimal.zero) { $0 + $1.sgdAmount * $1.cadence.renewalsPerYear() }
    }

    // MARK: - Coming year

    static func comingYear(
        subscriptions: [SubscriptionSnapshot],
        useFilter: UseFilter,
        today: Date,
        calendar: Calendar = .current
    ) -> Decimal {
        comingYearByMonth(subscriptions: subscriptions, useFilter: useFilter, today: today, calendar: calendar)
            .reduce(Decimal.zero) { $0 + $1.total }
    }

    static func comingYearByMonth(
        subscriptions: [SubscriptionSnapshot],
        useFilter: UseFilter,
        today: Date,
        calendar: Calendar = .current
    ) -> [(monthStart: Date, total: Decimal)] {
        let todayDay = startOfDay(today, calendar: calendar)
        guard let end = calendar.date(byAdding: .month, value: 12, to: todayDay) else { return [] }
        var buckets: [Date: Decimal] = [:]

        for sub in subscriptions where useFilter.matches(sub.use) {
            for date in chargeDatesInComingYear(for: sub, today: todayDay, end: end, calendar: calendar) {
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
                buckets[monthStart, default: 0] += sub.sgdAmount
            }
        }

        return buckets.keys.sorted().map { ($0, buckets[$0] ?? 0) }
    }

    static func chargeDatesInComingYear(
        for sub: SubscriptionSnapshot,
        today: Date,
        end: Date,
        calendar: Calendar = .current
    ) -> [Date] {
        switch sub.state {
        case .cancelled:
            return []
        case .trial, .active:
            break
        }

        let firstChargeDay = startOfDay(sub.renewalDate, calendar: calendar)
        guard firstChargeDay <= end else { return [] }

        if sub.state == .trial {
            if firstChargeDay >= today && firstChargeDay <= end {
                return [firstChargeDay]
            }
            return []
        }

        var dates: [Date] = []
        var cursor = firstChargeDay
        if cursor < today {
            while cursor < today {
                let next = sub.cadence.advance(cursor, calendar: calendar)
                if next == cursor { break }
                cursor = next
            }
        }
        while cursor <= end {
            if cursor >= today {
                dates.append(cursor)
            }
            let next = sub.cadence.advance(cursor, calendar: calendar)
            if next == cursor { break }
            cursor = next
        }
        return dates
    }

    static func nextChargeDates(
        for sub: SubscriptionSnapshot,
        from today: Date,
        limit: Int,
        calendar: Calendar = .current
    ) -> [Date] {
        guard sub.state != .cancelled else { return [] }
        let todayDay = startOfDay(today, calendar: calendar)
        var dates: [Date] = []
        var cursor = startOfDay(sub.renewalDate, calendar: calendar)

        if sub.state == .trial {
            if cursor >= todayDay { dates.append(cursor) }
            return dates
        }

        if cursor < todayDay {
            while cursor < todayDay {
                let next = sub.cadence.advance(cursor, calendar: calendar)
                if next == cursor { break }
                cursor = next
            }
        }
        while dates.count < limit {
            if cursor >= todayDay {
                dates.append(cursor)
            }
            let next = sub.cadence.advance(cursor, calendar: calendar)
            if next == cursor { break }
            cursor = next
            if dates.count >= limit { break }
        }
        return Array(dates.prefix(limit))
    }

    static func sgdDueInNextDays(
        subscriptions: [SubscriptionSnapshot],
        days: Int,
        today: Date,
        calendar: Calendar = .current
    ) -> Decimal {
        let todayDay = startOfDay(today, calendar: calendar)
        guard let end = calendar.date(byAdding: .day, value: days, to: todayDay) else { return 0 }
        var total: Decimal = 0
        for sub in subscriptions where sub.state != .cancelled {
            if sub.state == .trial {
                let day = startOfDay(sub.renewalDate, calendar: calendar)
                if day >= todayDay, day <= end { total += sub.sgdAmount }
                continue
            }
            var cursor = startOfDay(sub.renewalDate, calendar: calendar)
            if cursor < todayDay {
                while cursor < todayDay {
                    let next = sub.cadence.advance(cursor, calendar: calendar)
                    if next == cursor { break }
                    cursor = next
                }
            }
            while cursor <= end {
                if cursor >= todayDay { total += sub.sgdAmount }
                let next = sub.cadence.advance(cursor, calendar: calendar)
                if next == cursor { break }
                cursor = next
            }
        }
        return total
    }

    // MARK: - Draft backfill

    static func draftChargeDates(
        chargesBegan: Date,
        through lastPassedRenewal: Date,
        cadence: Cadence,
        calendar: Calendar = .current
    ) -> [Date] {
        RenewalSchedule.dates(from: chargesBegan, through: lastPassedRenewal, cadence: cadence, calendar: calendar)
    }

    // MARK: - Delta

    static func priceDelta(from charges: [ChargeLine]) -> Decimal? {
        let confirmed = charges.filter(\.isConfirmed).sorted { $0.date < $1.date }
        guard confirmed.count >= 2 else { return nil }
        return confirmed[confirmed.count - 1].sgdAmount - confirmed[confirmed.count - 2].sgdAmount
    }

    // MARK: - Helpers

    static func countsTowardRunRate(_ sub: SubscriptionSnapshot) -> Bool {
        switch sub.state {
        case .cancelled: return false
        case .active, .trial: return true
        }
    }

    static func willRenew(_ sub: SubscriptionSnapshot, today: Date, calendar: Calendar = .current) -> Bool {
        switch sub.state {
        case .cancelled: return false
        case .trial, .active:
            return startOfDay(sub.renewalDate, calendar: calendar) >= startOfDay(today, calendar: calendar)
                || sub.state == .active
        }
    }
}
