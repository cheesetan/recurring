//
//  BrandMark.swift
//  recurring
//

import Foundation

enum BrandMark: String, CaseIterable {
    case netflix
    case spotify
    case icloud
    case youtube
    case chatgpt
    case claude
    case adobe
    case github
    case disney
    case amazon
    case notion
    case apple
    case google
    case cursor
    case simba

    var assetName: String { "brand-\(rawValue)" }

    /// Longest whole-word brand in `name`, punctuation ignored. Earlier token wins a length tie.
    static func matching(_ name: String) -> BrandMark? {
        let tokens = tokens(in: name)
        let hits = allCases.filter { tokens.contains($0.rawValue) }
        return hits.max { lhs, rhs in
            if lhs.rawValue.count != rhs.rawValue.count {
                return lhs.rawValue.count < rhs.rawValue.count
            }
            let leftIndex = tokens.firstIndex(of: lhs.rawValue) ?? 0
            let rightIndex = tokens.firstIndex(of: rhs.rawValue) ?? 0
            return leftIndex > rightIndex
        }
    }

    /// `+` is a symbol, not punctuation, so `Disney+` and `iCloud+` need both sets.
    private static let tokenEdges = CharacterSet.punctuationCharacters.union(.symbols)

    private static func tokens(in name: String) -> [String] {
        name.split(whereSeparator: \.isWhitespace).compactMap { word in
            let token = String(word)
                .trimmingCharacters(in: tokenEdges)
                .lowercased()
            return token.isEmpty ? nil : token
        }
    }
}
