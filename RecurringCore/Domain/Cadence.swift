//
//  Cadence.swift
//  recurring
//

import Foundation

enum CadenceKind: String, Codable, CaseIterable, Identifiable {
    case weekly
    case monthly
    case quarterly
    case yearly
    case everyWeeks
    case everyMonths

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weekly: "weekly"
        case .monthly: "monthly"
        case .quarterly: "quarterly"
        case .yearly: "yearly"
        case .everyWeeks: "every N weeks"
        case .everyMonths: "every N months"
        }
    }
}

struct Cadence: Codable, Equatable, Hashable {
    var kind: CadenceKind
    /// Used when kind is everyWeeks or everyMonths; must be >= 1.
    var interval: Int

    init(kind: CadenceKind, interval: Int = 1) {
        self.kind = kind
        self.interval = max(1, interval)
    }

    static let weekly = Cadence(kind: .weekly)
    static let monthly = Cadence(kind: .monthly)
    static let quarterly = Cadence(kind: .quarterly)
    static let yearly = Cadence(kind: .yearly)

    func renewalsPerYear() -> Decimal {
        switch kind {
        case .weekly: 52
        case .monthly: 12
        case .quarterly: 4
        case .yearly: 1
        case .everyWeeks: Decimal(52) / Decimal(interval)
        case .everyMonths: Decimal(12) / Decimal(interval)
        }
    }

    func advance(_ date: Date, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: date)
        switch kind {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? start
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: start) ?? start
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: start) ?? start
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: start) ?? start
        case .everyWeeks:
            return calendar.date(byAdding: .weekOfYear, value: interval, to: start) ?? start
        case .everyMonths:
            return calendar.date(byAdding: .month, value: interval, to: start) ?? start
        }
    }

    func retreat(_ date: Date, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: date)
        switch kind {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: start) ?? start
        case .monthly:
            return calendar.date(byAdding: .month, value: -1, to: start) ?? start
        case .quarterly:
            return calendar.date(byAdding: .month, value: -3, to: start) ?? start
        case .yearly:
            return calendar.date(byAdding: .year, value: -1, to: start) ?? start
        case .everyWeeks:
            return calendar.date(byAdding: .weekOfYear, value: -interval, to: start) ?? start
        case .everyMonths:
            return calendar.date(byAdding: .month, value: -interval, to: start) ?? start
        }
    }
}

enum RenewalSchedule {
    /// All renewal dates from `from` through `through`, stepping backward then forward from `anchor`.
    static func dates(
        from start: Date,
        through end: Date,
        cadence: Cadence,
        calendar: Calendar = .current
    ) -> [Date] {
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        guard startDay <= endDay else { return [] }

        var cursor = calendar.startOfDay(for: start)
        while cursor > endDay {
            let next = cadence.advance(cursor, calendar: calendar)
            if next == cursor { break }
            cursor = next
        }
        while cursor < startDay {
            let next = cadence.advance(cursor, calendar: calendar)
            if next == cursor { break }
            cursor = next
        }

        var result: [Date] = []
        var current = cursor
        while current <= endDay {
            if current >= startDay {
                result.append(current)
            }
            let next = cadence.advance(current, calendar: calendar)
            if next == current { break }
            current = next
        }
        return result
    }

    /// Renewal dates strictly after `after` up to `through`.
    static func upcomingDates(
        after: Date,
        through: Date,
        cadence: Cadence,
        calendar: Calendar = .current
    ) -> [Date] {
        let afterDay = calendar.startOfDay(for: after)
        let throughDay = calendar.startOfDay(for: through)
        guard afterDay < throughDay else { return [] }

        var cursor = calendar.startOfDay(for: after)
        var first = cadence.advance(cursor, calendar: calendar)
        if first <= afterDay {
            first = cadence.advance(first, calendar: calendar)
        }
        var result: [Date] = []
        var current = first
        while current <= throughDay {
            result.append(current)
            let next = cadence.advance(current, calendar: calendar)
            if next == current { break }
            current = next
        }
        return result
    }
}
