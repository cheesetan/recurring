//
//  ChargeRecorder.swift
//  recurring
//

import Foundation
import SwiftData

enum ChargeRecorder {
    static func processDueCharges(context: ModelContext, today: Date = Date()) throws {
        let calendar = Calendar.current
        let todayDay = calendar.startOfDay(for: today)
        let subs = try context.fetch(FetchDescriptor<Subscription>())

        for sub in subs {
            switch sub.state {
            case .cancelled:
                continue
            case .trial:
                if ChargeAutomation.trialShouldConvert(renewalDate: sub.renewalDate, today: todayDay, calendar: calendar) {
                    sub.state = .active
                    insertCharge(for: sub, on: calendar.startOfDay(for: sub.renewalDate), context: context)
                    sub.renewalDate = sub.cadence.advance(sub.renewalDate, calendar: calendar)
                }
            case .active:
                let existingDates = Set((sub.charges ?? []).map { calendar.startOfDay(for: $0.date) })
                let due = ChargeAutomation.dueRenewalDates(
                    renewalDate: sub.renewalDate,
                    cadence: sub.cadence,
                    today: todayDay,
                    existingChargeDates: existingDates,
                    calendar: calendar
                )
                for day in due {
                    insertCharge(for: sub, on: day, context: context, confirmed: true)
                }
                sub.renewalDate = ChargeAutomation.nextRenewalAfterProcessing(
                    renewalDate: sub.renewalDate,
                    cadence: sub.cadence,
                    today: todayDay,
                    calendar: calendar
                )
            }
        }
        try context.save()
    }

    static func insertCharge(
        for sub: Subscription,
        on date: Date,
        context: ModelContext,
        confirmed: Bool = true
    ) {
        let charge = Charge(date: date, sgdAmount: sub.sgdAmount, isConfirmed: confirmed)
        charge.subscription = sub
        context.insert(charge)
        if sub.charges == nil { sub.charges = [] }
        sub.charges?.append(charge)
    }

    static func createDraftBackfill(for sub: Subscription, context: ModelContext, calendar: Calendar = .current) throws {
        guard let began = sub.chargesBeganDate else { return }
        let todayDay = calendar.startOfDay(for: Date())
        var lastPassed = sub.renewalDate
        if lastPassed > todayDay {
            lastPassed = sub.cadence.retreat(lastPassed, calendar: calendar)
        }
        while lastPassed > todayDay {
            lastPassed = sub.cadence.retreat(lastPassed, calendar: calendar)
        }
        let dates = SpendEngine.draftChargeDates(
            chargesBegan: began,
            through: lastPassed,
            cadence: sub.cadence,
            calendar: calendar
        )
        let existing = Set((sub.charges ?? []).map { calendar.startOfDay(for: $0.date) })
        for day in dates where !existing.contains(calendar.startOfDay(for: day)) {
            insertCharge(for: sub, on: calendar.startOfDay(for: day), context: context, confirmed: false)
        }
        try context.save()
    }
}
