//
//  SubscriptionFormView.swift
//  recurring
//

import SwiftData
import SwiftUI

struct SubscriptionFormView: View {
    var showsCancel: Bool = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var state: SubscriptionState = .active
    @State private var use: SubscriptionUse = .personal
    @State private var renewalDate = Calendar.current.startOfDay(for: Date())
    @State private var cadenceKind: CadenceKind = .monthly
    @State private var cadenceInterval = 1
    @State private var sgdAmount: Decimal = 0
    @State private var billedAmount: Decimal?
    @State private var billedCurrencyCode = "SGD"
    @State private var leadTimeDays = AppConstants.defaultLeadTimeDays
    @State private var note = ""
    @State private var paymentNickname = ""
    @State private var chargesBeganDate: Date?
    @State private var paidThrough: Date?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                formCard("subscription") {
                    labeledField("name") {
                        TextField("name", text: $name)
                            .font(AppTypography.rowTitle())
                    }
                    Text("state")
                        .font(AppTypography.meta())
                        .foregroundStyle(AppTheme.inkSecondary)
                    pillRow(SubscriptionState.allCases, selection: $state) { $0.rawValue }
                    Text("use")
                        .font(AppTypography.meta())
                        .foregroundStyle(AppTheme.inkSecondary)
                    pillRow(SubscriptionUse.allCases, selection: $use) { $0.label }
                    DatePicker("renewal", selection: $renewalDate, displayedComponents: .date)
                        .font(AppTypography.figureLabel())
                    if state == .cancelled {
                        DatePicker("paid through", selection: Binding(
                            get: { paidThrough ?? renewalDate },
                            set: { paidThrough = Calendar.current.startOfDay(for: $0) }
                        ), displayedComponents: .date)
                        .font(AppTypography.figureLabel())
                    }
                }

                formCard("cadence") {
                    pillRow(CadenceKind.allCases, selection: $cadenceKind) { $0.label }
                    if cadenceKind == .everyWeeks || cadenceKind == .everyMonths {
                        Stepper("every \(cadenceInterval)", value: $cadenceInterval, in: 1...52)
                            .font(AppTypography.figureLabel())
                    }
                }

                formCard("amounts") {
                    labeledField("SGD charged") {
                        TextField("0", value: $sgdAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .font(AppTypography.rowTitle())
                    }
                    labeledField("billed amount") {
                        TextField("0.00", value: Binding(
                            get: { billedAmount ?? sgdAmount },
                            set: { billedAmount = $0 }
                        ), format: .number.precision(.fractionLength(2...2)))
                        .keyboardType(.decimalPad)
                        .font(AppTypography.rowTitle())
                    }
                    labeledField("billed currency") {
                        TextField("SGD", text: $billedCurrencyCode)
                            .textInputAutocapitalization(.characters)
                            .font(AppTypography.rowTitle())
                    }
                }

                formCard("optional") {
                    Stepper("lead time: \(leadTimeDays) days", value: $leadTimeDays, in: 0...30)
                        .font(AppTypography.figureLabel())
                    labeledField("note") {
                        TextField("note", text: $note, axis: .vertical)
                            .font(AppTypography.figureLabel())
                    }
                    labeledField("payment nickname") {
                        TextField("payment nickname", text: $paymentNickname)
                            .font(AppTypography.figureLabel())
                    }
                }

                formCard("history") {
                    Toggle("backfill past charges", isOn: Binding(
                        get: { chargesBeganDate != nil },
                        set: { on in
                            chargesBeganDate = on ? Calendar.current.date(byAdding: .year, value: -1, to: Date()) : nil
                        }
                    ))
                    .font(AppTypography.figureLabel())
                    .tint(AppTheme.accent)
                    if chargesBeganDate != nil {
                        DatePicker("charges began", selection: Binding(
                            get: { chargesBeganDate ?? Date() },
                            set: { chargesBeganDate = Calendar.current.startOfDay(for: $0) }
                        ), displayedComponents: .date)
                        .font(AppTypography.figureLabel())
                    }
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .screenCanvas()
        .navigationTitle("new subscription")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCancel {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("save") { save() }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
            }
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && sgdAmount > 0
    }

    private func formCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppTypography.sectionTitle())
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private func labeledField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTypography.meta())
                .foregroundStyle(AppTheme.inkSecondary)
            content()
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.canvasTop, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
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

    private func save() {
        let cadence = Cadence(kind: cadenceKind, interval: cadenceInterval)
        let calendar = Calendar.current
        let sub = Subscription(
            name: name,
            state: state,
            use: use,
            renewalDate: calendar.startOfDay(for: renewalDate),
            cadence: cadence,
            sgdAmount: sgdAmount,
            billedAmount: billedAmount,
            billedCurrencyCode: billedCurrencyCode,
            leadTimeDays: leadTimeDays
        )
        modelContext.insert(sub)
        sub.note = note.isEmpty ? nil : note
        sub.paymentNickname = paymentNickname.isEmpty ? nil : paymentNickname
        sub.paidThrough = state == .cancelled ? calendar.startOfDay(for: paidThrough ?? renewalDate) : nil

        if let chargesBeganDate {
            sub.chargesBeganDate = calendar.startOfDay(for: chargesBeganDate)
            try? ChargeRecorder.createDraftBackfill(for: sub, context: modelContext)
        }

        try? ChargeRecorder.processDueCharges(context: modelContext)
        Task { await NotificationScheduler.rescheduleAll(context: modelContext) }
        WidgetRefresh.now()
        dismiss()
    }
}

struct NewSubscriptionSheet: View {
    var body: some View {
        NavigationStack {
            SubscriptionFormView(showsCancel: true)
        }
    }
}
