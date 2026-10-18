//
//  SubscriptionRowView.swift
//  recurring
//

import SwiftUI

struct SubscriptionRowView: View {
    let subscription: Subscription

    private var monogramColor: Color {
        AppTheme.monogramColor(for: subscription.name)
    }

    private var relativeRenewal: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let day = calendar.startOfDay(for: subscription.renewalDate)
        let days = calendar.dateComponents([.day], from: today, to: day).day ?? 0
        if days < 0 { return "overdue" }
        if days == 0 { return "today" }
        if days == 1 { return "tomorrow" }
        return "in \(days) days"
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(subscription.monogram)
                .font(AppTypography.rowTitle())
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(monogramColor.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(subscription.name)
                .font(AppTypography.rowTitle())
                .lineLimit(1)

            if subscription.state == .trial {
                Text("trial")
                    .font(AppTypography.meta())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15), in: Capsule())
                    .foregroundStyle(.orange)
            }
            if subscription.use == .business {
                Text("business")
                    .font(AppTypography.meta())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.15), in: Capsule())
                    .foregroundStyle(.blue)
            }

            Spacer(minLength: 8)

            Text(relativeRenewal)
                .font(AppTypography.meta())
                .foregroundStyle(relativeRenewal == "overdue" ? Color.red : AppTheme.inkSecondary)
                .lineLimit(1)

            Text(subscription.sgdAmount, format: .currency(code: "SGD"))
                .font(.moneyRow())
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}
