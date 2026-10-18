//
//  Theme.swift
//  recurring
//

import SwiftUI

enum AppTheme {
    static let accent = Color("AccentColor")

    static let canvasTop = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.11, blue: 0.12, alpha: 1)
            : UIColor(red: 0.99, green: 0.97, blue: 0.94, alpha: 1)
    })

    static let canvasBottom = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1)
            : UIColor(red: 0.94, green: 0.90, blue: 0.86, alpha: 1)
    })

    static let canvas = canvasBottom

    static let card = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.16, green: 0.15, blue: 0.17, alpha: 1)
            : UIColor.white
    })

    static let inkSecondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.68, alpha: 1)
            : UIColor(red: 0.42, green: 0.38, blue: 0.34, alpha: 1)
    })

    static let chartMuted = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.42, green: 0.44, blue: 0.48, alpha: 1)
            : UIColor(red: 0.72, green: 0.68, blue: 0.62, alpha: 1)
    })

    static let monogramPalette: [Color] = [
        Color(red: 0.88, green: 0.42, blue: 0.32),
        Color(red: 0.55, green: 0.45, blue: 0.78),
        Color(red: 0.28, green: 0.58, blue: 0.52),
        Color(red: 0.82, green: 0.55, blue: 0.28),
        Color(red: 0.38, green: 0.52, blue: 0.78),
        Color(red: 0.72, green: 0.38, blue: 0.48),
    ]

    static func monogramColor(for name: String) -> Color {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return monogramPalette[0] }
        var hash = 0
        for scalar in trimmed.unicodeScalars {
            hash = (hash &* 31 &+ Int(scalar.value)) & 0x7FFF_FFFF
        }
        return monogramPalette[abs(hash) % monogramPalette.count]
    }
}

enum AppTypography {
    static func sectionTitle() -> Font {
        .system(.title3, design: .rounded).weight(.semibold)
    }

    static func rowTitle() -> Font {
        .system(.headline, design: .rounded).weight(.semibold)
    }

    static func meta() -> Font {
        .system(.caption, design: .rounded).weight(.medium)
    }

    static func figureLabel() -> Font {
        .system(.subheadline, design: .rounded).weight(.medium)
    }
}

extension Font {
    static func moneyHero() -> Font {
        .system(.largeTitle, design: .rounded).weight(.bold)
    }

    static func moneyRow() -> Font {
        .system(.headline, design: .rounded).weight(.semibold)
    }

    static func moneyCaption() -> Font {
        .system(.subheadline, design: .rounded).weight(.medium)
    }
}

struct ScreenCanvasBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.canvasTop, AppTheme.canvasBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [AppTheme.accent.opacity(0.16), AppTheme.accent.opacity(0.02), .clear],
                center: UnitPoint(x: 0.85, y: 0.02),
                startRadius: 10,
                endRadius: 420
            )
        }
    }
}

struct CardModifier: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

extension View {
    func appCard(padding: CGFloat = 16) -> some View {
        modifier(CardModifier(padding: padding))
    }

    func screenCanvas() -> some View {
        background {
            ScreenCanvasBackground()
                .ignoresSafeArea()
        }
    }
}
