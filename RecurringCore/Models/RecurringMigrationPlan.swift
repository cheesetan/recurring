//
//  RecurringMigrationPlan.swift
//  recurring
//

import Foundation
import SwiftData

enum RecurringMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [RecurringSchemaV1.self, RecurringSchemaV2.self, RecurringSchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3]
    }

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: RecurringSchemaV1.self,
        toVersion: RecurringSchemaV2.self,
        willMigrate: { context in
            let legacy = try context.fetch(FetchDescriptor<RecurringSchemaV1.LegacySubscription>())
            let calendar = Calendar.current
            let today = Date()
            for old in legacy {
                let occurrence = LegacyOccurrence(rawValue: old.occurence.rawValue) ?? .monthly
                let cadence = occurrence.toCadence()
                let renewal = occurrence.nextRenewal(from: old.startDate, today: today, calendar: calendar)
                let price = Decimal(old.price)
                let sub = RecurringSchemaV2.Subscription(
                    name: old.name,
                    state: .active,
                    use: .personal,
                    renewalDate: calendar.startOfDay(for: renewal),
                    cadence: cadence,
                    sgdAmount: price,
                    billedAmount: price,
                    billedCurrencyCode: "SGD"
                )
                context.insert(sub)
                context.delete(old)
            }
            try context.save()
        },
        didMigrate: nil
    )

    static let migrateV2toV3 = MigrationStage.custom(
        fromVersion: RecurringSchemaV2.self,
        toVersion: RecurringSchemaV3.self,
        willMigrate: { context in
            let subscriptions = try context.fetch(FetchDescriptor<RecurringSchemaV2.Subscription>())
            for subscription in subscriptions {
                subscription.tags = []
                subscription.explicitPrimaryTagID = nil
            }
            let tags = try context.fetch(FetchDescriptor<RecurringSchemaV2.Tag>())
            for tag in tags {
                context.delete(tag)
            }
            try context.save()
        },
        didMigrate: nil
    )
}
