//
//  Subscription.swift
//  recurring
//
//  Created by Tristan Chay on 2/2/26.
//

import Foundation
import SwiftData

@Model
final class Subscription {
    var name: String
    var startDate: Date
    var occurence: Occurence
    var price: Double

    private func addOneInterval(to date: Date) -> Date {
        switch occurence {
        case .weekly:
            return Calendar.current.date(byAdding: .weekOfMonth, value: 1, to: date) ?? date
        case .monthly:
            return Calendar.current.date(byAdding: .month, value: 1, to: date) ?? date
        case .yearly:
            return Calendar.current.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }

    var renewalDate: Date {
        let now = Date()

        if startDate > now {
            return startDate
        }

        var next = startDate
        while next <= now {
            let advanced = addOneInterval(to: next)
            if advanced == next { break }
            next = advanced
        }

        return next
    }

    enum Occurence: String, Codable, CaseIterable {
        case weekly, monthly, yearly
    }

    init(name: String, startDate: Date, occurence: Occurence, price: Double) {
        self.name = name
        self.startDate = startDate
        self.occurence = occurence
        self.price = price
    }
}

