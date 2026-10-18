//
//  UpcomingView.swift
//  recurring
//

import Charts
import SwiftData
import SwiftUI

private enum ListVisibility: String, CaseIterable, Identifiable {
    case active
    case all

    var id: Self { self }

    var title: String {
        switch self {
        case .active: "active & trial"
        case .all: "active, trial & cancelled"
        }
    }

    var symbol: String {
        switch self {
        case .active: "line.3.horizontal.decrease.circle"
        case .all: "line.3.horizontal.decrease.circle.fill"
        }
    }
}

private enum RenewalBucket: CaseIterable, Identifiable {
    case thisWeek
    case thisMonth
    case later
    case cancelled

    var id: Self { self }

    var title: String {
        switch self {
        case .thisWeek: "this week"
        case .thisMonth: "this month"
        case .later: "later"
        case .cancelled: "cancelled"
        }
    }
}

struct UpcomingView: View {
    @Binding var useFilter: UseFilter
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subscription.renewalDate) private var subscriptions: [Subscription]

    @State private var visibility: ListVisibility = .active
    @State private var showingAdd = false
    @State private var showingSettings = false
    @State private var showingCharts = false

    private var snapshots: [SubscriptionSnapshot] {
        SubscriptionQueryHelpers.allSnapshots(subscriptions)
    }

    private var visibleBuckets: [RenewalBucket] {
        RenewalBucket.allCases.filter { !subscriptions(in: $0).isEmpty }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 16) {
                        UseFilterControl(filter: $useFilter)
                        figuresHero
                    }
                    Button {
                        showingCharts = true
                    } label: {
                        cashPreview
                    }
                    .buttonStyle(.plain)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if visibleBuckets.isEmpty {
                ContentUnavailableView(
                    "no subscriptions",
                    systemImage: "singaporedollarsign.arrow.trianglehead.counterclockwise.rotate.90",
                    description: Text("add a subscription to track renewals and spend.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(visibleBuckets) { bucket in
                    Section {
                        let items = subscriptions(in: bucket)
                        ForEach(items) { sub in
                            NavigationLink {
                                SubscriptionDetailView(subscription: sub)
                            } label: {
                                SubscriptionRowView(subscription: sub)
                            }
                            .listRowBackground(AppTheme.card)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            delete(items, at: offsets)
                        }
                    } header: {
                        Text(bucket.title)
                            .font(AppTypography.sectionTitle())
                            .foregroundStyle(.primary)
                            .textCase(nil)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .screenCanvas()
        .navigationTitle("recurring")
        .navigationSubtitle("\(useFilter.label) • \(visibility.title)")
        .navigationDestination(isPresented: $showingCharts) {
            ChartsView(useFilter: $useFilter)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("visibility", selection: $visibility) {
                        ForEach(ListVisibility.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    Image(systemName: visibility.symbol)
                }
                .accessibilityLabel(visibility.title)
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            NewSubscriptionSheet()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }

    private var figuresHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("run rate")
                .font(AppTypography.figureLabel())
                .foregroundStyle(AppTheme.inkSecondary)
            Text(SpendEngine.runRate(subscriptions: snapshots, useFilter: useFilter), format: .currency(code: "SGD"))
                .font(.moneyHero())
                .foregroundStyle(AppTheme.accent)
                .contentTransition(.numericText())

            HStack(spacing: 12) {
                figureColumn(
                    title: "coming year",
                    value: SpendEngine.comingYear(subscriptions: snapshots, useFilter: useFilter, today: Date())
                )
                Divider()
                    .frame(height: 40)
                figureColumn(title: "cash (12 mo)", value: trailingTwelveMonthCash)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private var cashPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("cash")
                        .font(AppTypography.sectionTitle())
                    Text("more charts")
                        .font(AppTypography.meta())
                        .foregroundStyle(AppTheme.inkSecondary)
                }
                Spacer()
                Text(previewCashTotal, format: .currency(code: "SGD"))
                    .font(.moneyCaption())
                    .foregroundStyle(AppTheme.accent)
                    .contentTransition(.numericText())
            }
            Chart(previewCash, id: \.monthStart) { item in
                BarMark(
                    x: .value("month", item.monthStart, unit: .month),
                    y: .value("SGD", NSDecimalNumber(decimal: item.total).doubleValue)
                )
                .foregroundStyle(AppTheme.accent.gradient)
                .cornerRadius(4)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 88)
            .animation(.smooth, value: useFilter)
        }
        .appCard()
    }

    private func figureColumn(title: String, value: Decimal) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.meta())
                .foregroundStyle(AppTheme.inkSecondary)
            Text(value, format: .currency(code: "SGD"))
                .font(.moneyCaption())
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var previewCash: [(monthStart: Date, total: Decimal)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let from = calendar.date(byAdding: .month, value: -5, to: today) ?? today
        return SpendEngine.cashByMonth(
            charges: SubscriptionQueryHelpers.allChargeLines(subscriptions),
            subscriptionUses: SubscriptionQueryHelpers.useMap(subscriptions),
            useFilter: useFilter,
            from: from,
            through: today,
            calendar: calendar
        )
    }

    private var previewCashTotal: Decimal {
        previewCash.reduce(Decimal.zero) { $0 + $1.total }
    }

    private var trailingTwelveMonthCash: Decimal {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let from = calendar.date(byAdding: .month, value: -12, to: today) else { return 0 }
        return SpendEngine.cash(
            charges: SubscriptionQueryHelpers.allChargeLines(subscriptions),
            subscriptionUses: SubscriptionQueryHelpers.useMap(subscriptions),
            useFilter: useFilter,
            from: from,
            through: today,
            calendar: calendar
        )
    }

    private func subscriptions(in bucket: RenewalBucket) -> [Subscription] {
        switch bucket {
        case .cancelled:
            guard visibility == .all else { return [] }
            return subscriptions
                .filter { $0.state == .cancelled && useFilter.matches($0.use) }
                .sorted { $0.renewalDate < $1.renewalDate }
        case .thisWeek, .thisMonth, .later:
            return subscriptions
                .filter { $0.state != .cancelled && useFilter.matches($0.use) && renewalBucket(for: $0) == bucket }
                .sorted(by: sortRenewals)
        }
    }

    private func renewalBucket(for subscription: Subscription) -> RenewalBucket {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let day = calendar.startOfDay(for: subscription.renewalDate)
        if day < today { return .thisWeek }
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: today) ?? today
        if day <= weekEnd { return .thisWeek }
        guard let monthInterval = calendar.dateInterval(of: .month, for: today) else { return .later }
        let monthEnd = calendar.startOfDay(for: monthInterval.end.addingTimeInterval(-1))
        if day <= monthEnd { return .thisMonth }
        return .later
    }

    private func sortRenewals(_ lhs: Subscription, _ rhs: Subscription) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let leftOverdue = lhs.renewalDate < today
        let rightOverdue = rhs.renewalDate < today
        if leftOverdue != rightOverdue { return leftOverdue }
        return lhs.renewalDate < rhs.renewalDate
    }

    private func delete(_ items: [Subscription], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
        WidgetRefresh.now()
    }
}
