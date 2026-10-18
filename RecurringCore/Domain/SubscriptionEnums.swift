//
//  SubscriptionEnums.swift
//  recurring
//

import Foundation

enum SubscriptionState: String, Codable, CaseIterable, Identifiable {
    case trial
    case active
    case cancelled

    var id: String { rawValue }
}

enum SubscriptionUse: String, Codable, CaseIterable, Identifiable {
    case personal
    case business

    var id: String { rawValue }

    var label: String {
        switch self {
        case .personal: "personal"
        case .business: "business"
        }
    }
}

enum UseFilter: String, CaseIterable, Identifiable {
    case all
    case personal
    case business

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: "all"
        case .personal: "personal"
        case .business: "business"
        }
    }

    func matches(_ use: SubscriptionUse) -> Bool {
        switch self {
        case .all: true
        case .personal: use == .personal
        case .business: use == .business
        }
    }
}
