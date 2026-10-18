//
//  SchemaV3.swift
//  recurring
//

import Foundation
import SwiftData

enum RecurringSchemaV3: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(3, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Subscription.self, Charge.self]
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
        var chargesBeganDate: Date?

        @Relationship(deleteRule: .cascade)
        var charges: [Charge]?

        var state: SubscriptionState {
            get { SubscriptionState(rawValue: stateRaw) ?? .active }
            set { stateRaw = newValue.rawValue }
        }

        var use: SubscriptionUse {
            get { SubscriptionUse(rawValue: useRaw) ?? .personal }
            set { useRaw = newValue.rawValue }
        }

        var cadence: Cadence {
            get {
                let kind = CadenceKind(rawValue: cadenceKindRaw) ?? .monthly
                return Cadence(kind: kind, interval: cadenceInterval)
            }
            set {
                cadenceKindRaw = newValue.kind.rawValue
                cadenceInterval = newValue.interval
            }
        }

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
            self.cadence = cadence
            self.sgdAmount = sgdAmount
            self.billedAmount = billedAmount
            self.billedCurrencyCode = billedCurrencyCode
            self.leadTimeDays = leadTimeDays
        }

        func snapshot() -> SubscriptionSnapshot {
            SubscriptionSnapshot(
                id: id,
                name: name,
                state: state,
                use: use,
                renewalDate: renewalDate,
                paidThrough: paidThrough,
                cadence: cadence,
                sgdAmount: sgdAmount,
                leadTimeDays: leadTimeDays
            )
        }

        var monogram: String {
            String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
        }

        func chargeLines() -> [ChargeLine] {
            (charges ?? []).map {
                ChargeLine(
                    id: $0.id,
                    subscriptionID: id,
                    date: $0.date,
                    sgdAmount: $0.sgdAmount,
                    isConfirmed: $0.isConfirmed
                )
            }
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
}
