//
//  SchemaV1.swift
//  recurring
//

import Foundation
import SwiftData

enum RecurringSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [LegacySubscription.self]
    }

    @Model
    final class LegacySubscription {
        var name: String
        var startDate: Date
        var occurence: Occurence
        var price: Double

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
}
