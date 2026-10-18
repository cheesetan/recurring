//
//  ModelContainerProvider.swift
//  recurring
//

import Foundation
import SwiftData

enum ModelContainerProvider {
    static func makeShared() throws -> ModelContainer {
        migrateLegacyStoreIfNeeded()
        return try makeContainer(usesCloudKit: true)
    }

    static func makeForWidget() throws -> ModelContainer {
        let storeURL = sharedStoreURL()
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try makeContainer(usesCloudKit: false)
    }

    static func sharedStoreURL() -> URL {
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID) {
            return groupURL.appending(path: "recurring.store")
        }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appending(path: "recurring.store")
    }

    private static func makeContainer(usesCloudKit: Bool) throws -> ModelContainer {
        let schema = Schema(versionedSchema: RecurringSchemaV3.self)
        let cloudKit: ModelConfiguration.CloudKitDatabase = usesCloudKit
            ? .private(AppConstants.cloudKitContainerID)
            : .none
        let configuration = ModelConfiguration(
            "recurring",
            schema: schema,
            url: sharedStoreURL(),
            cloudKitDatabase: cloudKit
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: RecurringMigrationPlan.self,
            configurations: configuration
        )
    }

    /// Copies a store written to Application Support before the app group id matched.
    private static func migrateLegacyStoreIfNeeded() {
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID) else {
            return
        }
        let destination = groupURL.appending(path: "recurring.store")
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: destination.path) else { return }
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let legacy = appSupport.appending(path: "recurring.store")
        guard fileManager.fileExists(atPath: legacy.path) else { return }
        try? fileManager.createDirectory(at: groupURL, withIntermediateDirectories: true)
        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: legacy.path + suffix)
            let copy = URL(fileURLWithPath: destination.path + suffix)
            guard fileManager.fileExists(atPath: source.path) else { continue }
            try? fileManager.copyItem(at: source, to: copy)
        }
    }
}
