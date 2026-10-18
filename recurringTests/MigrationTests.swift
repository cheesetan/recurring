//
//  MigrationTests.swift
//  recurringTests
//

import Foundation
import SwiftData
import Testing
@testable import recurring

@MainActor
struct MigrationTests {
    @Test func v2StoreKeepsSubscriptionsAndCharges() throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "recurring-migration-\(UUID().uuidString).store")
        defer { Self.removeStore(at: url) }

        let subscriptionID = UUID()
        let chargeID = UUID()
        let renewal = Date(timeIntervalSince1970: 1_800_000_000)

        do {
            let schema = Schema(versionedSchema: RecurringSchemaV2.self)
            let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: configuration)
            let context = container.mainContext
            let subscription = RecurringSchemaV2.Subscription(
                name: "Netflix",
                renewalDate: renewal,
                sgdAmount: 16
            )
            subscription.id = subscriptionID
            let tag = RecurringSchemaV2.Tag(name: "video")
            let charge = RecurringSchemaV2.Charge(date: renewal, sgdAmount: 16, isConfirmed: true)
            charge.id = chargeID
            charge.subscription = subscription
            subscription.tags = [tag]
            subscription.explicitPrimaryTagID = tag.id
            context.insert(subscription)
            context.insert(tag)
            context.insert(charge)
            try context.save()
        }

        let schema = Schema(versionedSchema: RecurringSchemaV3.self)
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: RecurringMigrationPlan.self,
            configurations: configuration
        )
        let subscriptions = try container.mainContext.fetch(FetchDescriptor<Subscription>())

        #expect(subscriptions.count == 1)
        let subscription = try #require(subscriptions.first)
        #expect(subscription.id == subscriptionID)
        #expect(subscription.name == "Netflix")
        #expect(subscription.sgdAmount == 16)
        let charges = subscription.charges ?? []
        #expect(charges.count == 1)
        #expect(charges.first?.id == chargeID)
        #expect(charges.first?.isConfirmed == true)
    }

    private static func removeStore(at url: URL) {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: url)
        try? fileManager.removeItem(at: URL(fileURLWithPath: url.path + "-shm"))
        try? fileManager.removeItem(at: URL(fileURLWithPath: url.path + "-wal"))
    }
}
