//
//  ChargeAutomation.swift
//  recurring
//

import Foundation

enum ChargeAutomation {
    /// Dates on or before `today` that should become charges, excluding dates that already have a charge.
    static func dueRenewalDates(
        renewalDate: Date,
        cadence: Cadence,
        today: Date,
        existingChargeDates: Set<Date>,
        calendar: Calendar = .current
    ) -> [Date] {
        let todayDay = calendar.startOfDay(for: today)
        var dates: [Date] = []
        var cursor = calendar.startOfDay(for: renewalDate)

        while cursor <= todayDay {
            if !existingChargeDates.contains(cursor) {
                dates.append(cursor)
            }
            let next = cadence.advance(cursor, calendar: calendar)
            if next == cursor { break }
            cursor = next
        }
        return dates
    }

    static func nextRenewalAfterProcessing(
        renewalDate: Date,
        cadence: Cadence,
        today: Date,
        calendar: Calendar = .current
    ) -> Date {
        let todayDay = calendar.startOfDay(for: today)
        var cursor = calendar.startOfDay(for: renewalDate)
        while cursor <= todayDay {
            let next = cadence.advance(cursor, calendar: calendar)
            if next == cursor { return cursor }
            cursor = next
        }
        return cursor
    }

    static func trialShouldConvert(
        renewalDate: Date,
        today: Date,
        calendar: Calendar = .current
    ) -> Bool {
        calendar.startOfDay(for: renewalDate) <= calendar.startOfDay(for: today)
    }
}
