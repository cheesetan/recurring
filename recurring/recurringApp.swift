//
//  recurringApp.swift
//  recurring
//
//  Created by Tristan Chay on 2/2/26.
//

import SwiftUI
import SwiftData

@main
struct recurringApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Subscription.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
