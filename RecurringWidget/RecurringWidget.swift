//
//  RecurringWidget.swift
//  RecurringWidget
//

import AppIntents
import Charts
import SwiftData
import SwiftUI
import WidgetKit

private enum WidgetTheme {
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.92, green: 0.48, blue: 0.38, alpha: 1)
            : UIColor(red: 0.88, green: 0.42, blue: 0.32, alpha: 1)
    })

    static let inkSecondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.68, alpha: 1)
            : UIColor(red: 0.42, green: 0.38, blue: 0.34, alpha: 1)
    })

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

    static let chartMuted = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.42, green: 0.44, blue: 0.48, alpha: 1)
            : UIColor(red: 0.72, green: 0.68, blue: 0.62, alpha: 1)
    })
}

private struct WidgetCanvas: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [WidgetTheme.canvasTop, WidgetTheme.canvasBottom], startPoint: .top, endPoint: .bottom)
            RadialGradient(
                colors: [WidgetTheme.accent.opacity(0.18), .clear],
                center: UnitPoint(x: 0.9, y: 0.05),
                startRadius: 8,
                endRadius: 220
            )
        }
    }
}

enum WidgetUse: String, AppEnum {
    case all
    case personal
    case business

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "use")

    static var caseDisplayRepresentations: [WidgetUse: DisplayRepresentation] = [
        .all: "all",
        .personal: "personal",
        .business: "business",
    ]

    var filter: UseFilter {
        switch self {
        case .all: .all
        case .personal: .personal
        case .business: .business
        }
    }
}

struct UseFilterIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "use"
    static var description = IntentDescription("Show all, personal, or business.")

    @Parameter(title: "use", default: .all)
    var use: WidgetUse
}

private struct WidgetRenewal: Identifiable {
    let name: String
    let date: Date
    let amount: Decimal
    var id: String { "\(name)-\(date.timeIntervalSince1970)" }
}

private struct WidgetMonth: Identifiable {
    let monthStart: Date
    let total: Decimal
    var id: Date { monthStart }
}

private struct RenewalsEntry: TimelineEntry {
    let date: Date
    let renewals: [WidgetRenewal]
    let next30Days: Decimal
}

private struct RunRateEntry: TimelineEntry {
    let date: Date
    let runRate: Decimal
    let comingYear: Decimal
}

private struct CashEntry: TimelineEntry {
    let date: Date
    let total: Decimal
    let months: [WidgetMonth]
}

@MainActor
private enum WidgetLibrary {
    struct Loaded {
        var snapshots: [SubscriptionSnapshot]
        var charges: [ChargeLine]
        var uses: [UUID: SubscriptionUse]
    }

    static func load() -> Loaded {
        guard let container = try? ModelContainerProvider.makeForWidget() else {
            return Loaded(snapshots: [], charges: [], uses: [:])
        }
        let subs = (try? container.mainContext.fetch(FetchDescriptor<Subscription>())) ?? []
        return Loaded(
            snapshots: subs.map { $0.snapshot() },
            charges: subs.flatMap { $0.chargeLines() },
            uses: Dictionary(uniqueKeysWithValues: subs.map { ($0.id, $0.use) })
        )
    }

    static func renewals(use: UseFilter, limit: Int) -> [WidgetRenewal] {
        let today = Date()
        var items: [WidgetRenewal] = []
        for snap in load().snapshots where snap.state != .cancelled && use.matches(snap.use) {
            for date in SpendEngine.nextChargeDates(for: snap, from: today, limit: 1) {
                items.append(WidgetRenewal(name: snap.name, date: date, amount: snap.sgdAmount))
            }
        }
        return Array(items.sorted { $0.date < $1.date }.prefix(limit))
    }

    static func next30Days(use: UseFilter) -> Decimal {
        let loaded = load()
        return SpendEngine.sgdDueInNextDays(subscriptions: loaded.snapshots.filter { use.matches($0.use) }, days: 30, today: Date())
    }

    static func runRate(use: UseFilter) -> Decimal {
        SpendEngine.runRate(subscriptions: load().snapshots, useFilter: use)
    }

    static func comingYear(use: UseFilter) -> Decimal {
        SpendEngine.comingYear(subscriptions: load().snapshots, useFilter: use, today: Date())
    }

    static func trailingCash(use: UseFilter) -> (Decimal, [WidgetMonth]) {
        let loaded = load()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let from = calendar.date(byAdding: .month, value: -12, to: today) ?? today
        let total = SpendEngine.cash(
            charges: loaded.charges,
            subscriptionUses: loaded.uses,
            useFilter: use,
            from: from,
            through: today,
            calendar: calendar
        )
        let months = SpendEngine.cashByMonth(
            charges: loaded.charges,
            subscriptionUses: loaded.uses,
            useFilter: use,
            from: from,
            through: today,
            calendar: calendar
        ).map { WidgetMonth(monthStart: $0.monthStart, total: $0.total) }
        return (total, months)
    }
}

private func renewalLimit(for family: WidgetFamily) -> Int {
    switch family {
    case .systemSmall: 1
    case .systemMedium: 3
    case .systemLarge: 7
    case .systemExtraLarge: 12
    default: 3
    }
}

private func nextTimelineDate() -> Date {
    Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date().addingTimeInterval(21600)
}

private struct RenewalsProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> RenewalsEntry {
        RenewalsEntry(
            date: Date(),
            renewals: [WidgetRenewal(name: "Netflix", date: Date(), amount: 15.98)],
            next30Days: 15.98
        )
    }

    func snapshot(for configuration: UseFilterIntent, in context: Context) async -> RenewalsEntry {
        await entry(for: configuration, family: context.family)
    }

    func timeline(for configuration: UseFilterIntent, in context: Context) async -> Timeline<RenewalsEntry> {
        let entry = await entry(for: configuration, family: context.family)
        return Timeline(entries: [entry], policy: .after(nextTimelineDate()))
    }

    private func entry(for configuration: UseFilterIntent, family: WidgetFamily) async -> RenewalsEntry {
        await MainActor.run {
            let use = configuration.use.filter
            return RenewalsEntry(
                date: Date(),
                renewals: WidgetLibrary.renewals(use: use, limit: renewalLimit(for: family)),
                next30Days: WidgetLibrary.next30Days(use: use)
            )
        }
    }
}

private struct RunRateProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> RunRateEntry {
        RunRateEntry(date: Date(), runRate: 2400, comingYear: 2100)
    }

    func snapshot(for configuration: UseFilterIntent, in context: Context) async -> RunRateEntry {
        await entry(for: configuration)
    }

    func timeline(for configuration: UseFilterIntent, in context: Context) async -> Timeline<RunRateEntry> {
        Timeline(entries: [await entry(for: configuration)], policy: .after(nextTimelineDate()))
    }

    private func entry(for configuration: UseFilterIntent) async -> RunRateEntry {
        await MainActor.run {
            let use = configuration.use.filter
            return RunRateEntry(
                date: Date(),
                runRate: WidgetLibrary.runRate(use: use),
                comingYear: WidgetLibrary.comingYear(use: use)
            )
        }
    }
}

private struct CashProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CashEntry {
        CashEntry(date: Date(), total: 180, months: [WidgetMonth(monthStart: Date(), total: 40)])
    }

    func snapshot(for configuration: UseFilterIntent, in context: Context) async -> CashEntry {
        await entry(for: configuration)
    }

    func timeline(for configuration: UseFilterIntent, in context: Context) async -> Timeline<CashEntry> {
        Timeline(entries: [await entry(for: configuration)], policy: .after(nextTimelineDate()))
    }

    private func entry(for configuration: UseFilterIntent) async -> CashEntry {
        await MainActor.run {
            let (total, months) = WidgetLibrary.trailingCash(use: configuration.use.filter)
            return CashEntry(date: Date(), total: total, months: months)
        }
    }
}

private struct RenewalsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RenewalsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemLarge || family == .systemExtraLarge ? 8 : 6) {
            Text("renewals")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(WidgetTheme.inkSecondary)
            if entry.renewals.isEmpty {
                Text("none")
                    .font(.system(.subheadline, design: .rounded))
            } else if family == .systemExtraLarge {
                let mid = (entry.renewals.count + 1) / 2
                HStack(alignment: .top, spacing: 16) {
                    renewalColumn(Array(entry.renewals.prefix(mid)))
                    renewalColumn(Array(entry.renewals.dropFirst(mid)))
                }
            } else {
                renewalColumn(entry.renewals)
            }
            Spacer(minLength: 0)
            HStack {
                Text("next 30 days")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(WidgetTheme.inkSecondary)
                Spacer()
                Text(entry.next30Days, format: .currency(code: "SGD"))
                    .font(.system(family == .systemSmall ? .subheadline : .headline, design: .rounded).weight(.bold))
                    .foregroundStyle(WidgetTheme.accent)
            }
        }
        .padding(.vertical, family == .systemMedium ? 16 : 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func renewalColumn(_ items: [WidgetRenewal]) -> some View {
        VStack(alignment: .leading, spacing: family == .systemMedium ? 8 : 6) {
            ForEach(items) { item in
                if family == .systemMedium {
                    mediumRenewalRow(item)
                } else {
                    renewalRow(item)
                }
            }
        }
    }

    /// One line per renewal so the medium widget can keep its vertical inset.
    private func mediumRenewalRow(_ item: WidgetRenewal) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(item.name)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .lineLimit(1)
            Text(item.date.formatted(date: .abbreviated, time: .omitted))
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(WidgetTheme.inkSecondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            Spacer(minLength: 8)
            Text(item.amount, format: .currency(code: "SGD"))
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(WidgetTheme.accent)
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    private func renewalRow(_ item: WidgetRenewal) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .lineLimit(1)
                if family != .systemSmall {
                    Text(item.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(WidgetTheme.inkSecondary)
                }
            }
            Spacer(minLength: 4)
            Text(item.amount, format: .currency(code: "SGD"))
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(WidgetTheme.accent)
        }
    }
}

private struct RunRateWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RunRateEntry

    private var heroSize: CGFloat {
        switch family {
        case .systemExtraLarge: 68
        case .systemLarge: 52
        case .systemMedium: 40
        default: 28
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("run rate")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(WidgetTheme.inkSecondary)
            Text(entry.runRate, format: .currency(code: "SGD"))
                .font(.system(size: heroSize, weight: .bold, design: .rounded))
                .foregroundStyle(WidgetTheme.accent)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            if family != .systemSmall {
                Text("coming year")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(WidgetTheme.inkSecondary)
                Text(entry.comingYear, format: .currency(code: "SGD"))
                    .font(.system(.title3, design: .rounded).weight(.semibold))
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CashWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CashEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("cash")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(WidgetTheme.inkSecondary)
            Text(entry.total, format: .currency(code: "SGD"))
                .font(.system(family == .systemSmall ? .title2 : .title, design: .rounded).weight(.bold))
                .foregroundStyle(WidgetTheme.accent)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            if family == .systemLarge || family == .systemExtraLarge {
                Spacer(minLength: 0)
                cashChart
            } else if family != .systemSmall {
                cashChart
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var cashChart: some View {
        Chart(entry.months) { month in
            BarMark(
                x: .value("month", month.monthStart, unit: .month),
                y: .value("SGD", NSDecimalNumber(decimal: month.total).doubleValue)
            )
            .foregroundStyle(WidgetTheme.accent.gradient)
            .cornerRadius(3)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: family == .systemMedium ? 72 : 120)
    }
}

private struct RenewalsWidget: Widget {
    let kind = "RenewalsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: UseFilterIntent.self, provider: RenewalsProvider()) { entry in
            RenewalsWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetCanvas() }
        }
        .configurationDisplayName("renewals")
        .description("Next renewals and SGD due in 30 days.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

private struct RunRateWidget: Widget {
    let kind = "RunRateWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: UseFilterIntent.self, provider: RunRateProvider()) { entry in
            RunRateWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetCanvas() }
        }
        .configurationDisplayName("run rate")
        .description("Run rate and coming year.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

private struct CashWidget: Widget {
    let kind = "CashWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: UseFilterIntent.self, provider: CashProvider()) { entry in
            CashWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetCanvas() }
        }
        .configurationDisplayName("cash")
        .description("Trailing twelve months of cash.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

@main
struct RecurringWidgetBundle: WidgetBundle {
    var body: some Widget {
        RenewalsWidget()
        RunRateWidget()
        CashWidget()
    }
}
