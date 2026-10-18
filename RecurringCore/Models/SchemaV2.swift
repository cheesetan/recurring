//
//  SchemaV2.swift
//  recurring
//

import Foundation
import SwiftData

enum RecurringSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Subscription.self, Charge.self, Tag.self]
    }

    @Model
    final class Subscription {
        var id: UUID = UUID()
        var name: String = ""
        var stateRaw: String = SubscriptionState.active.rawValue
        var useRaw: String = SubscriptionUse.personal.rawValue
        var renewalDate: Date = Date()
        var paidThrough: Date?
        var cadenceKindRaw: String = CadenceKind.monthly.rawValue
        var cadenceInterval: Int = 1
        var sgdAmount: Decimal = 0
        var billedAmount: Decimal?
        var billedCurrencyCode: String?
        var leadTimeDays: Int = 3
        var note: String?
        var paymentNickname: String?
        var explicitPrimaryTagID: UUID?
        var chargesBeganDate: Date?

        @Relationship(deleteRule: .cascade)
        var charges: [Charge]?

        @Relationship
        var tags: [Tag]?

        init(
            name: String,
            state: SubscriptionState = .active,
            use: SubscriptionUse = .personal,
            renewalDate: Date,
            cadence: Cadence = .monthly,
            sgdAmount: Decimal = 0,
            billedAmount: Decimal? = nil,
            billedCurrencyCode: String? = nil,
            leadTimeDays: Int = 3
        ) {
            self.id = UUID()
            self.name = name
            self.stateRaw = state.rawValue
            self.useRaw = use.rawValue
            self.renewalDate = renewalDate
            self.cadenceKindRaw = cadence.kind.rawValue
            self.cadenceInterval = cadence.interval
            self.sgdAmount = sgdAmount
            self.billedAmount = billedAmount
            self.billedCurrencyCode = billedCurrencyCode
            self.leadTimeDays = leadTimeDays
        }
    }

    @Model
    final class Charge {
        var id: UUID = UUID()
        var date: Date = Date()
        var sgdAmount: Decimal = 0
        var isConfirmed: Bool = false

        var subscription: Subscription?

        init(date: Date, sgdAmount: Decimal, isConfirmed: Bool = false) {
            self.id = UUID()
            self.date = date
            self.sgdAmount = sgdAmount
            self.isConfirmed = isConfirmed
        }
    }

    @Model
    final class Tag {
        var id: UUID = UUID()
        var name: String = ""
        var colorHex: String = "#007AFF"

        @Relationship(inverse: \Subscription.tags)
        var subscriptions: [Subscription]?

        init(name: String, colorHex: String = "#007AFF") {
            self.id = UUID()
            self.name = name
            self.colorHex = colorHex
        }
    }
}
