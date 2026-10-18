//
//  SubscriptionDetailView.swift
//  recurring
//

import SwiftData
import SwiftUI

struct SubscriptionDetailView: View {
    @Bindable var subscription: Subscription
    @Environment(\.modelContext) private var modelContext
    @State private var editing: SubscriptionFact?
    @State private var showsInlineTitle = false
    @State private var scrollTopInset: CGFloat = 0

    private var confirmedCharges: [Charge] {
        Array(
            (subscription.charges ?? [])
                .filter(\.isConfirmed)
                .sorted { $0.date > $1.date }
                .prefix(6)
        )
    }

    private var hasDrafts: Bool {
        (subscription.charges ?? []).contains { !$0.isConfirmed }
    }

    private var showsCharges: Bool {
        hasDrafts || !confirmedCharges.isEmpty
    }

    var body: some View {
        List {
            Section {
                hero
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section {
                factRow("cadence", value: cadenceText) { editing = .cadence }
                factRow("renewal", value: subscription.renewalDate.formatted(date: .abbreviated, time: .omitted)) {
                    editing = .renewal
                }
                factRow("state", value: subscription.state.rawValue) { editing = .state }
                if subscription.state == .cancelled {
                    factRow("paid through", value: paidThroughText) { editing = .paidThrough }
                }
                factRow("lead time", value: leadTimeText(subscription.leadTimeDays)) { editing = .leadTime }
            } header: {
                sectionHeader("schedule")
            }

            Section {
                factRow("SGD charged", value: subscription.sgdAmount.formatted(.currency(code: "SGD"))) {
                    editing = .sgd
                }
                factRow("billed price", value: billedPriceText) { editing = .billedPrice }
            } header: {
                sectionHeader("money")
            }

            Section {
                factRow("use", value: subscription.use.label) { editing = .use }
                factRow("payment nickname", value: optionalText(subscription.paymentNickname)) {
                    editing = .paymentNickname
                }
                factRow("note", value: optionalText(subscription.note), lineLimit: 2) { editing = .note }
            } header: {
                sectionHeader("account")
            }

            if showsCharges {
                Section {
                    if hasDrafts {
                        NavigationLink {
                            DraftChargesView(subscription: subscription)
                        } label: {
                            Text("review drafts")
                                .font(AppTypography.figureLabel())
                                .foregroundStyle(.primary)
                        }
                        .listRowBackground(AppTheme.card)
                    }
                    ForEach(confirmedCharges) { charge in
                        HStack {
                            Text(charge.date.formatted(date: .abbreviated, time: .omitted))
                                .font(AppTypography.meta())
                                .foregroundStyle(AppTheme.inkSecondary)
                            Spacer(minLength: 12)
                            Text(charge.sgdAmount, format: .currency(code: "SGD"))
                                .font(.moneyCaption())
                                .foregroundStyle(AppTheme.inkSecondary)
                        }
                        .listRowBackground(AppTheme.card)
                    }
                } header: {
                    sectionHeader("history")
                }
            }
        }
        .listStyle(.insetGrouped)
        .contentMargins(.top, 0, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .screenCanvas()
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentInsets.top
        } action: { _, newValue in
            guard abs(scrollTopInset - newValue) > 0.5 else { return }
            scrollTopInset = newValue
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(subscription.name)
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(1)
                    .opacity(showsInlineTitle ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: showsInlineTitle)
                    .accessibilityHidden(!showsInlineTitle)
            }
        }
        .sheet(item: $editing) { fact in
            SubscriptionFactSheet(fact: fact, subscription: subscription, onCommit: commitSideEffects)
        }
    }

    private var hero: some View {
        let scrollTopInset = scrollTopInset
        return VStack(spacing: 10) {
            heroMark

            VStack(spacing: 4) {
                Button {
                    editing = .name
                } label: {
                    Text(subscription.name)
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .onGeometryChange(for: Bool.self) { proxy in
                    let frame = proxy.frame(in: .scrollView)
                    return frame.height > 0 && frame.maxY <= scrollTopInset
                } action: { isOffscreen in
                    guard showsInlineTitle != isOffscreen else { return }
                    showsInlineTitle = isOffscreen
                }

                if subscription.state == .trial || subscription.use == .business {
                    HStack(spacing: 6) {
                        if subscription.state == .trial {
                            badge("trial", color: .orange)
                        }
                        if subscription.use == .business {
                            badge("business", color: .blue)
                        }
                    }
                }

                VStack(spacing: 1) {
                    Text(subscription.sgdAmount, format: .currency(code: "SGD"))
                        .font(.moneyHero())
                        .foregroundStyle(subscription.state == .cancelled ? AppTheme.inkSecondary : AppTheme.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .contentTransition(.numericText())

                    if let billedHeroText {
                        Text(billedHeroText)
                            .font(AppTypography.meta())
                            .foregroundStyle(AppTheme.inkSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }

                Text(heroLine.text)
                    .font(AppTypography.figureLabel())
                    .foregroundStyle(heroLine.isOverdue ? Color.red : AppTheme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }

    private var heroMark: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        let side: CGFloat = 72
        return Group {
            if let brand = BrandMark.matching(subscription.name) {
                Image(brand.assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: side, height: side)
                    .clipShape(shape)
            } else {
                Text(subscription.monogram)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: side, height: side)
                    .background(AppTheme.monogramColor(for: subscription.name).gradient, in: shape)
            }
        }
        .accessibilityHidden(true)
    }

    private var heroLine: (text: String, isOverdue: Bool) {
        if subscription.state == .cancelled {
            if let paidThrough = subscription.paidThrough {
                return ("cancelled · paid through \(shortDate(paidThrough))", false)
            }
            return ("cancelled", false)
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let day = calendar.startOfDay(for: subscription.renewalDate)
        let days = calendar.dateComponents([.day], from: today, to: day).day ?? 0
        if days < 0 { return ("overdue", true) }

        let date = shortDate(day)
        if days == 0 { return ("today · \(date)", false) }
        if days == 1 { return ("tomorrow · \(date)", false) }
        return ("in \(days) days · \(date)", false)
    }

    private var cadenceText: String {
        let cadence = subscription.cadence
        return switch cadence.kind {
        case .weekly: "weekly"
        case .monthly: "monthly"
        case .quarterly: "quarterly"
        case .yearly: "yearly"
        case .everyWeeks:
            "every \(cadence.interval) \(cadence.interval == 1 ? "week" : "weeks")"
        case .everyMonths:
            "every \(cadence.interval) \(cadence.interval == 1 ? "month" : "months")"
        }
    }

    /// Foreign or distinct billed price, written as `65.40 USD`. Hidden when it repeats the SGD charge.
    private var billedHeroText: String? {
        guard let amount = subscription.billedAmount else { return nil }
        let code = subscription.billedCurrencyCode?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased() ?? ""
        if code.isEmpty { return BilledPrice.amount(amount) }
        if code == "SGD", amount == subscription.sgdAmount { return nil }
        return "\(BilledPrice.amount(amount)) \(code)"
    }

    private var billedPriceText: String {
        guard let amount = subscription.billedAmount else { return "add" }
        let code = subscription.billedCurrencyCode?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased() ?? ""
        guard !code.isEmpty else { return BilledPrice.amount(amount) }
        return "\(BilledPrice.amount(amount)) \(code)"
    }

    private var paidThroughText: String {
        guard let paidThrough = subscription.paidThrough else { return "add" }
        return paidThrough.formatted(date: .abbreviated, time: .omitted)
    }

    private func leadTimeText(_ days: Int) -> String {
        switch days {
        case 0: "same day"
        case 1: "1 day"
        default: "\(days) days"
        }
    }

    private func optionalText(_ value: String?) -> String {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "add" : trimmed
    }

    private func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.sectionTitle())
            .foregroundStyle(.primary)
            .textCase(nil)
    }

    private func factRow(
        _ label: String,
        value: String,
        lineLimit: Int = 1,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(AppTypography.figureLabel())
                    .foregroundStyle(.primary)
                Spacer(minLength: 16)
                Text(value)
                    .font(AppTypography.figureLabel())
                    .foregroundStyle(AppTheme.accent)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(lineLimit)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(AppTheme.card)
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

    private func commitSideEffects() {
        try? ChargeRecorder.processDueCharges(context: modelContext)
        Task { await NotificationScheduler.rescheduleAll(context: modelContext) }
        WidgetRefresh.now()
    }
}

private enum FactFocus: Hashable {
    case primary
    case currency
}

private enum SubscriptionFact: String, Identifiable {
    case name
    case cadence
    case renewal
    case state
    case paidThrough
    case leadTime
    case sgd
    case billedPrice
    case use
    case paymentNickname
    case note

    var id: String { rawValue }

    var title: String {
        switch self {
        case .name: "name"
        case .cadence: "cadence"
        case .renewal: "renewal"
        case .state: "state"
        case .paidThrough: "paid through"
        case .leadTime: "lead time"
        case .sgd: "SGD charged"
        case .billedPrice: "billed price"
        case .use: "use"
        case .paymentNickname: "payment nickname"
        case .note: "note"
        }
    }

    var focusesField: Bool {
        switch self {
        case .name, .sgd, .billedPrice, .paymentNickname, .note: true
        case .cadence, .renewal, .state, .paidThrough, .leadTime, .use: false
        }
    }
}

private struct SubscriptionFactSheet: View {
    let fact: SubscriptionFact
    let subscription: Subscription
    let onCommit: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var state: SubscriptionState
    @State private var use: SubscriptionUse
    @State private var renewalDate: Date
    @State private var cadenceKind: CadenceKind
    @State private var cadenceInterval: Int
    @State private var sgdAmount: Decimal
    @State private var billedAmountText: String
    @State private var billedCurrency: String
    @State private var leadTimeDays: Int
    @State private var note: String
    @State private var paymentNickname: String
    @State private var paidThrough: Date
    @State private var appeared = false
    @State private var didCommit = false
    @State private var contentHeight: CGFloat = 0
    @State private var chromeHeight: CGFloat = 0
    @FocusState private var focusedField: FactFocus?

    init(fact: SubscriptionFact, subscription: Subscription, onCommit: @escaping () -> Void) {
        self.fact = fact
        self.subscription = subscription
        self.onCommit = onCommit
        _name = State(initialValue: subscription.name)
        _state = State(initialValue: subscription.state)
        _use = State(initialValue: subscription.use)
        _renewalDate = State(initialValue: subscription.renewalDate)
        _cadenceKind = State(initialValue: subscription.cadence.kind)
        _cadenceInterval = State(initialValue: max(1, subscription.cadence.interval))
        _sgdAmount = State(initialValue: subscription.sgdAmount)
        _billedAmountText = State(initialValue: subscription.billedAmount.map(DetailAmount.string(from:)) ?? "")
        _billedCurrency = State(initialValue: subscription.billedCurrencyCode ?? "")
        _leadTimeDays = State(initialValue: subscription.leadTimeDays)
        _note = State(initialValue: subscription.note ?? "")
        _paymentNickname = State(initialValue: subscription.paymentNickname ?? "")
        _paidThrough = State(initialValue: subscription.paidThrough ?? subscription.renewalDate)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                editor
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { newValue in
                FittedSheet.assign($contentHeight, to: newValue)
            }
            .background {
                SheetChromeReader { newValue in
                    FittedSheet.assign($chromeHeight, to: newValue)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .screenCanvas()
            .navigationTitle(fact.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .fittedSheetDetents(content: contentHeight, chrome: chromeHeight)
        .onAppear {
            appeared = true
            if fact.focusesField {
                focusedField = .primary
            }
        }
        .onChange(of: draft) { _, _ in
            apply()
        }
        .onDisappear {
            guard appeared, !didCommit else { return }
            didCommit = true
            apply()
            onCommit()
        }
    }

    @ViewBuilder
    private var editor: some View {
        switch fact {
        case .name:
            textField("name", text: $name)
        case .cadence:
            pillRow(CadenceKind.allCases, selection: $cadenceKind) { $0.label }
            if cadenceKind == .everyWeeks || cadenceKind == .everyMonths {
                Stepper("every \(cadenceInterval)", value: $cadenceInterval, in: 1...52)
                    .font(AppTypography.figureLabel())
            }
        case .renewal:
            DatePicker("renewal", selection: $renewalDate, displayedComponents: .date)
                .font(AppTypography.figureLabel())
        case .state:
            pillRow(SubscriptionState.allCases, selection: $state) { $0.rawValue }
            if state == .cancelled {
                DatePicker("paid through", selection: $paidThrough, displayedComponents: .date)
                    .font(AppTypography.figureLabel())
            }
        case .paidThrough:
            DatePicker("paid through", selection: $paidThrough, displayedComponents: .date)
                .font(AppTypography.figureLabel())
        case .leadTime:
            Stepper(leadTimeText(leadTimeDays), value: $leadTimeDays, in: 0...30)
                .font(AppTypography.figureLabel())
        case .sgd:
            TextField("0", value: $sgdAmount, format: .number)
                .keyboardType(.decimalPad)
                .font(AppTypography.rowTitle())
                .focused($focusedField, equals: .primary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.canvasTop, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        case .billedPrice:
            textField("amount", text: $billedAmountText, decimalPad: true)
            textField("currency", text: $billedCurrency, characters: true, focus: .currency)
        case .use:
            pillRow(SubscriptionUse.allCases, selection: $use) { $0.label }
        case .paymentNickname:
            textField("payment nickname", text: $paymentNickname)
        case .note:
            textField("note", text: $note, axis: .vertical)
        }
    }

    private func textField(
        _ prompt: String,
        text: Binding<String>,
        decimalPad: Bool = false,
        characters: Bool = false,
        axis: Axis = .horizontal,
        focus: FactFocus = .primary
    ) -> some View {
        TextField(prompt, text: text, axis: axis)
            .textInputAutocapitalization(characters ? .characters : .sentences)
            .keyboardType(decimalPad ? .decimalPad : .default)
            .lineLimit(axis == .vertical ? 1...8 : 1...1)
            .font(axis == .vertical ? AppTypography.figureLabel() : AppTypography.rowTitle())
            .focused($focusedField, equals: focus)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.canvasTop, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func pillRow<Option: Hashable & Identifiable>(
        _ options: [Option],
        selection: Binding<Option>,
        label: @escaping (Option) -> String
    ) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(options) { option in
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        Text(label(option))
                            .font(AppTypography.figureLabel())
                            .padding(.horizontal, 14)
                            .frame(minHeight: 44)
                            .background(
                                selection.wrappedValue == option ? AppTheme.accent : AppTheme.canvasTop,
                                in: Capsule()
                            )
                            .foregroundStyle(selection.wrappedValue == option ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, -16)
    }

    private var draft: Draft {
        Draft(
            name: name,
            state: state,
            use: use,
            renewalDate: renewalDate,
            cadenceKind: cadenceKind,
            cadenceInterval: cadenceInterval,
            sgdAmount: sgdAmount,
            billedAmountText: billedAmountText,
            billedCurrency: billedCurrency,
            leadTimeDays: leadTimeDays,
            note: note,
            paymentNickname: paymentNickname,
            paidThrough: paidThrough
        )
    }

    private struct Draft: Equatable {
        var name: String
        var state: SubscriptionState
        var use: SubscriptionUse
        var renewalDate: Date
        var cadenceKind: CadenceKind
        var cadenceInterval: Int
        var sgdAmount: Decimal
        var billedAmountText: String
        var billedCurrency: String
        var leadTimeDays: Int
        var note: String
        var paymentNickname: String
        var paidThrough: Date
    }

    private func leadTimeText(_ days: Int) -> String {
        switch days {
        case 0: "same day"
        case 1: "1 day"
        default: "\(days) days"
        }
    }

    private func apply() {
        let calendar = Calendar.current
        switch fact {
        case .name:
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                subscription.name = trimmed
            }
        case .cadence:
            subscription.cadence = Cadence(kind: cadenceKind, interval: cadenceInterval)
        case .renewal:
            subscription.renewalDate = calendar.startOfDay(for: renewalDate)
        case .state:
            subscription.state = state
            if state == .cancelled {
                subscription.paidThrough = calendar.startOfDay(for: paidThrough)
            } else {
                subscription.paidThrough = nil
            }
        case .paidThrough:
            subscription.paidThrough = calendar.startOfDay(for: paidThrough)
        case .leadTime:
            subscription.leadTimeDays = leadTimeDays
        case .sgd:
            subscription.sgdAmount = sgdAmount
        case .billedPrice:
            let trimmed = billedAmountText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                subscription.billedAmount = nil
                subscription.billedCurrencyCode = nil
            } else if let amount = DetailAmount.decimal(from: trimmed) {
                subscription.billedAmount = amount
                let code = billedCurrency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                subscription.billedCurrencyCode = code.isEmpty ? nil : code
            }
        case .use:
            subscription.use = use
        case .paymentNickname:
            subscription.paymentNickname = trimmedOrNil(paymentNickname)
        case .note:
            subscription.note = trimmedOrNil(note)
        }
    }

    private func trimmedOrNil(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

extension View {
    func fittedSheetDetents(content: CGFloat, chrome: CGFloat) -> some View {
        modifier(FittedSheetDetents(contentHeight: content, chromeHeight: chrome))
    }
}

/// One shared height for the fitted detent. Only one of these sheets is presented at a time.
private final class FittedDetentBox {
    static let shared = FittedDetentBox()
    var height: CGFloat = 200
}

/// Stable detent identity. Changing `.height` builds a new detent and the sheet snaps;
/// this type stays put, and UIKit animates when its resolved height is invalidated.
private struct FittedDetent: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        min(max(FittedDetentBox.shared.height, 1), context.maxDetentValue)
    }
}

/// Keeps an exact-height sheet on a stable custom detent and animates when that height changes.
private struct FittedSheetDetents: ViewModifier {
    var contentHeight: CGFloat
    var chromeHeight: CGFloat

    private var resolved: CGFloat {
        FittedSheet.height(content: contentHeight, chrome: chromeHeight)
    }

    func body(content: Content) -> some View {
        content
            .presentationDetents([.custom(FittedDetent.self)])
            .presentationDragIndicator(.hidden)
            .background {
                FittedSheetResizer(height: resolved)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
    }
}

private struct FittedSheetResizer: UIViewRepresentable {
    var height: CGFloat

    func makeUIView(context: Context) -> FittedSheetResizerView {
        FittedSheetResizerView()
    }

    func updateUIView(_ view: FittedSheetResizerView, context: Context) {
        view.setHeight(height)
    }
}

private final class FittedSheetResizerView: UIView {
    private var target: CGFloat = 0
    private var applied: CGFloat = -1
    private var applying = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        nil
    }

    func setHeight(_ height: CGFloat) {
        guard height > 1, abs(target - height) > 0.5 else { return }
        target = height
        FittedDetentBox.shared.height = height
        apply()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard target > 1 else { return }
        FittedDetentBox.shared.height = target
        apply()
    }

    private func apply() {
        guard !applying, target > 1, window != nil, let sheet else { return }
        applying = true
        defer { applying = false }
        let changed = abs(applied - target) > 0.5
        let first = applied < 0
        applied = target
        guard changed else { return }
        if first {
            UIView.performWithoutAnimation {
                sheet.invalidateDetents()
            }
        } else {
            sheet.animateChanges {
                sheet.invalidateDetents()
            }
        }
    }

    private var sheet: UISheetPresentationController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let controller = current as? UIViewController {
                if let sheet = controller.sheetPresentationController
                    ?? controller.navigationController?.sheetPresentationController
                    ?? controller.parent?.sheetPresentationController {
                    return sheet
                }
            }
            responder = current.next
        }
        return nil
    }
}

enum FittedSheet {
    static func height(content: CGFloat, chrome: CGFloat) -> CGFloat {
        let measured = content + chrome
        let height = measured > 1 ? measured : 200
        return min(max(height, 1), maximumHeight)
    }

    static func assign(_ height: Binding<CGFloat>, to newValue: CGFloat) {
        guard newValue > 0, abs(height.wrappedValue - newValue) > 0.5 else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            height.wrappedValue = newValue
        }
    }

    private static var maximumHeight: CGFloat {
        let screen = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .screen.bounds.height
        return max((screen ?? 800) - 20, 1)
    }
}

/// Reports the navigation bar height that sits above the measured content.
struct SheetChromeReader: UIViewRepresentable {
    var onChrome: (CGFloat) -> Void

    func makeUIView(context: Context) -> ChromeProbeView {
        let view = ChromeProbeView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        view.onChrome = onChrome
        return view
    }

    func updateUIView(_ uiView: ChromeProbeView, context: Context) {
        uiView.onChrome = onChrome
        uiView.publish()
    }

    final class ChromeProbeView: UIView {
        var onChrome: ((CGFloat) -> Void)?
        private var lastChrome: CGFloat = -1

        override func didMoveToWindow() {
            super.didMoveToWindow()
            publish()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            publish()
        }

        func publish() {
            guard window != nil else { return }
            let chrome = navigationChrome
            guard chrome > 0, abs(lastChrome - chrome) > 0.5 else { return }
            lastChrome = chrome
            let onChrome = onChrome
            DispatchQueue.main.async {
                onChrome?(chrome)
            }
        }

        /// Distance from the top of the sheet to the bottom of its navigation bar.
        /// Mid-presentation frames report a stretched bar, so those readings are ignored.
        private var navigationChrome: CGFloat {
            var responder: UIResponder? = self
            while let current = responder {
                if let controller = current as? UIViewController, let navigation = controller.navigationController {
                    let bar = navigation.navigationBar
                    let barFrame = bar.convert(bar.bounds, to: nil)
                    guard (36...80).contains(barFrame.height) else { return 0 }
                    let sheetTop = navigation.view.convert(navigation.view.bounds, to: nil).minY
                    return max(0, barFrame.maxY - sheetTop)
                }
                responder = current.next
            }
            return 0
        }
    }
}

private enum DetailAmount {
    nonisolated private static func formatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }

    nonisolated static func string(from amount: Decimal) -> String {
        formatter().string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
    }

    nonisolated static func decimal(from text: String) -> Decimal? {
        formatter().number(from: text)?.decimalValue
    }
}

enum BilledPrice {
    static func amount(_ amount: Decimal) -> String {
        DetailAmount.string(from: amount)
    }
}
