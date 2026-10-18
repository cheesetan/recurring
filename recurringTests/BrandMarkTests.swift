//
//  BrandMarkTests.swift
//  recurringTests
//

import Testing
@testable import recurring

struct BrandMarkTests {
    @Test(arguments: [
        ("Netflix", BrandMark.netflix),
        ("Spotify", BrandMark.spotify),
        ("Apple iCloud+", BrandMark.icloud),
        ("YouTube Premium", BrandMark.youtube),
        ("ChatGPT Plus", BrandMark.chatgpt),
        ("Claude Pro", BrandMark.claude),
        ("Adobe Creative Cloud", BrandMark.adobe),
        ("GitHub Copilot", BrandMark.github),
        ("Disney+", BrandMark.disney),
        ("Amazon Prime", BrandMark.amazon),
        ("Notion", BrandMark.notion),
        ("Apple", BrandMark.apple),
        ("Google", BrandMark.google),
        ("Cursor", BrandMark.cursor),
        ("SIMBA", BrandMark.simba),
        ("simba", BrandMark.simba),
    ])
    func knownNames(name: String, mark: BrandMark) {
        #expect(BrandMark.matching(name) == mark)
    }

    @Test func pineappleStaysUnmatched() {
        #expect(BrandMark.matching("Pineapple") == nil)
    }

    @Test func emptyAndUnknownStayUnmatched() {
        #expect(BrandMark.matching("") == nil)
        #expect(BrandMark.matching("   ") == nil)
        #expect(BrandMark.matching("Gym") == nil)
    }

    @Test func earlierTokenWinsEqualLength() {
        #expect(BrandMark.matching("Cursor Google") == .cursor)
        #expect(BrandMark.matching("Google Cursor") == .google)
    }
}
