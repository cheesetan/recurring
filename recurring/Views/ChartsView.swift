//
//  ChartsView.swift
//  recurring
//

import Charts
import SwiftData
import SwiftUI

enum CashRange: String, CaseIterable, Identifiable {
    case trailingTwelve
    case calendarYear
    case allTime

    var id: String { rawValue }

    var label: String {
        switch self {
        case .trailingTwelve: "last 12 months"
        case .calendarYear: "this year"
        case .allTime: "all time"
        }
    }
}

struct ChartsView: View {
    @Binding var useFilter: UseFilter
    @Query private var subscriptions: [Subscription]

    @State private var cashRange: CashRange = .trailingTwelve

    private var snapshots: [SubscriptionSnapshot] {
        SubscriptionQueryHelpers.allSnapshots(subscriptions)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                UseFilterControl(filter: $useFilter)

                HStack(spacing: 8) {
                    ForEach(CashRange.allCases) { range in
                        Button {
                            cashRange = range
                        } label: {
                            Text(range.label)
                                .font(AppTypography.meta())
                                .padding(.horizontal, 12)
                                .frame(minHeight: 44)
                                .background(
                                    cashRange == range ? Color.accentColor : AppTheme.card,
                                    in: Capsule()
                                )
                                .foregroundStyle(cashRange == range ? Color.white : Color.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                chartCard(
                    title: "cash by month",
                    total: cashByMonth.reduce(Decimal.zero) { $0 + $1.total },
                    emphasizesTotal: true
                ) {
                    Chart(cashByMonth, id: \.monthStart) { item in
                        BarMark(
                            x: .value("month", item.monthStart, unit: .month),
                            y: .value("SGD", NSDecimalNumber(decimal: item.total).doubleValue)
                        )
                        .foregroundStyle(Color.accentColor.gradient)
                        .cornerRadius(4)
                    }
                    .chartYAxisLabel("SGD")
                    .frame(height: 200)
                }

                chartCard(
                    title: "coming year by month",
                    total: comingYearByMonth.reduce(Decimal.zero) { $0 + $1.total },
                    emphasizesTotal: false
                ) {
                    Chart(comingYearByMonth, id: \.monthStart) { item in
                        BarMark(
                            x: .value("month", item.monthStart, unit: .month),
                            y: .value("SGD", NSDecimalNumber(decimal: item.total).doubleValue)
                        )
                        .foregroundStyle(AppTheme.chartMuted)
                        .cornerRadius(4)
                    }
                    .frame(height: 200)
                }
            }
            .padding(16)
        }
        .screenCanvas()
        .navigationTitle("charts")
    }

    private func chartCard<Content: View>(
        title: String,
        total: Decimal,
        emphasizesTotal: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.sectionTitle())
                Text(total, format: .currency(code: "SGD"))
                    .font(.moneyCaption())
                    .foregroundStyle(emphasizesTotal ? Color.accentColor : AppTheme.inkSecondary)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private var cashByMonth: [(monthStart: Date, total: Decimal)] {
        let (from, through) = cashBounds
        return SpendEngine.cashByMonth(
            charges: SubscriptionQueryHelpers.allChargeLines(subscriptions),
            subscriptionUses: SubscriptionQueryHelpers.useMap(subscriptions),
            useFilter: useFilter,
            from: from,
            through: through,
            calendar: Calendar.current
        )
    }

    private var comingYearByMonth: [(monthStart: Date, total: Decimal)] {
        SpendEngine.comingYearByMonth(subscriptions: snapshots, useFilter: useFilter, today: Date())
    }

    private var cashBounds: (Date, Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        switch cashRange {
        case .trailingTwelve:
            let from = calendar.date(byAdding: .month, value: -12, to: today) ?? today
            return (from, today)
        case .calendarYear:
            let from = calendar.date(from: calendar.dateComponents([.year], from: today)) ?? today
            return (from, today)
        case .allTime:
            let charges = SubscriptionQueryHelpers.allChargeLines(subscriptions).filter(\.isConfirmed)
            guard let minDate = charges.map(\.date).min() else { return (today, today) }
            return (minDate, today)
        }
    }
}
