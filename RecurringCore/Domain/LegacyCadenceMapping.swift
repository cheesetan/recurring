//
//  LegacyCadenceMapping.swift
//  recurring
//

import Foundation

/// Maps the pre-revamp `Occurence` enum stored in schema v1.
enum LegacyOccurrence: String, Codable {
    case weekly, monthly, yearly

    func toCadence() -> Cadence {
        switch self {
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        }
    }

    static func nextRenewal(from startDate: Date, today: Date, calendar: Calendar = .current) -> Date {
        let cadence = LegacyOccurrence.monthly.toCadence()
        _ = cadence
        let now = calendar.startOfDay(for: today)
        var start = calendar.startOfDay(for: startDate)
        if start > now { return start }
        var next = start
        while next <= now {
            let advanced = LegacyOccurrence.monthly.toCadence().advance(next, calendar: calendar)
            if advanced == next { break }
            next = advanced
        }
        return next
    }
}

extension LegacyOccurrence {
    func nextRenewal(from startDate: Date, today: Date, calendar: Calendar = .current) -> Date {
        let cadence = toCadence()
        let now = calendar.startOfDay(for: today)
        var start = calendar.startOfDay(for: startDate)
        if start > now { return start }
        var next = start
        while next <= now {
            let advanced = cadence.advance(next, calendar: calendar)
            if advanced == next { break }
            next = advanced
        }
        return next
    }
}
