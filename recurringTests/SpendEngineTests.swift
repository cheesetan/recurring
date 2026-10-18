//
//  SpendEngineTests.swift
//  recurringTests
//

import Foundation
import Testing
@testable import recurring

struct SpendEngineTests {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d))!
    }

    @Test func runRateMonthly() {
        let sub = SubscriptionSnapshot(
            id: UUID(),
            name: "Netflix",
            state: .active,
            use: .personal,
            renewalDate: date(2026, 11, 1),
            paidThrough: nil,
            cadence: .monthly,
            sgdAmount: 20,
            leadTimeDays: 3
        )
        let rate = SpendEngine.runRate(subscriptions: [sub], useFilter: .all)
        #expect(rate == 240)
    }

    @Test func useFilterExcludesBusinessFromPersonalCash() {
        let subID = UUID()
        let charges = [
            ChargeLine(id: UUID(), subscriptionID: subID, date: date(2026, 6, 1), sgdAmount: 10, isConfirmed: true),
        ]
        let uses = [subID: SubscriptionUse.business]
        let cash = SpendEngine.cash(
            charges: charges,
            subscriptionUses: uses,
            useFilter: .personal,
            from: date(2026, 1, 1),
            through: date(2026, 12, 31),
            calendar: calendar
        )
        #expect(cash == 0)
    }

    @Test func cancelledExcludedFromRunRate() {
        let sub = SubscriptionSnapshot(
            id: UUID(),
            name: "Adobe",
            state: .cancelled,
            use: .personal,
            renewalDate: date(2026, 1, 1),
            paidThrough: date(2026, 6, 30),
            cadence: .monthly,
            sgdAmount: 50,
            leadTimeDays: 3
        )
        #expect(SpendEngine.runRate(subscriptions: [sub], useFilter: .all) == 0)
    }

    @Test func cadenceAdvanceMonthly() {
        let start = date(2026, 1, 31)
        let next = Cadence.monthly.advance(start, calendar: calendar)
        let components = calendar.dateComponents([.year, .month, .day], from: next)
        #expect(components.month == 2)
    }

    @Test func priceDelta() {
        let subID = UUID()
        let charges = [
            ChargeLine(id: UUID(), subscriptionID: subID, date: date(2026, 1, 1), sgdAmount: 10, isConfirmed: true),
            ChargeLine(id: UUID(), subscriptionID: subID, date: date(2026, 2, 1), sgdAmount: 15, isConfirmed: true),
        ]
        #expect(SpendEngine.priceDelta(from: charges) == 5)
    }
}
