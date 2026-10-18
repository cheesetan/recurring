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
            mark

            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(AppTypography.rowTitle())
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(relativeRenewal)
                        .font(AppTypography.meta())
                        .foregroundStyle(relativeRenewal == "overdue" ? Color.red : AppTheme.inkSecondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    if subscription.state == .trial {
                        badge("trial", color: .orange)
                    }
                    if subscription.use == .business {
                        badge("business", color: .blue)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(subscription.sgdAmount, format: .currency(code: "SGD"))
                    .font(.moneyRow())
                    .lineLimit(1)
                if let billedLine {
                    Text(billedLine)
                        .font(AppTypography.meta())
                        .foregroundStyle(AppTheme.inkSecondary)
                        .lineLimit(1)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.vertical, 4)
    }

    /// Foreign or distinct billed price, written as `65.40 USD`. Hidden when it repeats the SGD charge.
    private var billedLine: String? {
        guard let amount = subscription.billedAmount else { return nil }
        let code = subscription.billedCurrencyCode?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased() ?? ""
        guard !code.isEmpty else { return nil }
        if code == "SGD", amount == subscription.sgdAmount { return nil }
        return "\(BilledPrice.amount(amount)) \(code)"
    }

    @ViewBuilder
    private var mark: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        if let brand = BrandMark.matching(subscription.name) {
            Image(brand.assetName)
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(shape)
                .accessibilityHidden(true)
        } else {
            Text(subscription.monogram)
                .font(AppTypography.rowTitle())
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(monogramColor.gradient, in: shape)
        }
    }

    private func badge(_ title: String, color: Color) -> some View {
        Text(title)
            .font(AppTypography.meta())
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}
