//
//  SubscriptionPresets.swift
//  recurring
//

import Foundation

struct SubscriptionPreset: Identifiable {
    var id: String { name }
    let name: String
    let cadence: Cadence
    let billedCurrencyCode: String?
}

enum SubscriptionPresets {
    static let all: [SubscriptionPreset] = [
        SubscriptionPreset(name: "Netflix", cadence: .monthly, billedCurrencyCode: "SGD"),
        SubscriptionPreset(name: "Spotify", cadence: .monthly, billedCurrencyCode: "SGD"),
        SubscriptionPreset(name: "Apple iCloud+", cadence: .monthly, billedCurrencyCode: "SGD"),
        SubscriptionPreset(name: "YouTube Premium", cadence: .monthly, billedCurrencyCode: "SGD"),
        SubscriptionPreset(name: "ChatGPT Plus", cadence: .monthly, billedCurrencyCode: "USD"),
        SubscriptionPreset(name: "Adobe Creative Cloud", cadence: .monthly, billedCurrencyCode: "USD"),
        SubscriptionPreset(name: "GitHub Copilot", cadence: .monthly, billedCurrencyCode: "USD"),
        SubscriptionPreset(name: "Disney+", cadence: .monthly, billedCurrencyCode: "SGD"),
        SubscriptionPreset(name: "Amazon Prime", cadence: .yearly, billedCurrencyCode: "SGD"),
        SubscriptionPreset(name: "Notion", cadence: .monthly, billedCurrencyCode: "USD"),
    ]
}
