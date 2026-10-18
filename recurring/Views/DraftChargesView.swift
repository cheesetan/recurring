//
//  DraftChargesView.swift
//  recurring
//

import SwiftData
import SwiftUI

struct DraftChargesView: View {
    @Bindable var subscription: Subscription
    @Environment(\.modelContext) private var modelContext

    private var drafts: [Charge] {
        (subscription.charges ?? []).filter { !$0.isConfirmed }.sorted { $0.date < $1.date }
    }

    private var draftTotal: Decimal {
        drafts.reduce(0) { $0 + $1.sgdAmount }
    }

    private var summaryLine: String {
        let count = drafts.count
        let noun = count == 1 ? "charge" : "charges"
        return "\(count) \(noun) · not counted as cash"
    }

    var body: some View {
        Group {
            if drafts.isEmpty {
                ContentUnavailableView(
                    "no drafts",
                    systemImage: "checkmark.circle",
                    description: Text("charges you confirm count as cash.")
                )
            } else {
                List {
                    Section {
                        summary
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }

                    Section {
                        ForEach(drafts) { draft in
                            DraftChargeRow(draft: draft)
                                .listRowBackground(AppTheme.card)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
            }
        }
        .screenCanvas()
        .navigationTitle("draft charges")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("drafts")
                    .font(AppTypography.figureLabel())
                    .foregroundStyle(AppTheme.inkSecondary)
                Text(draftTotal, format: .currency(code: "SGD"))
                    .font(.moneyHero())
                    .foregroundStyle(AppTheme.accent)
                    .contentTransition(.numericText())
                Text(summaryLine)
                    .font(AppTypography.meta())
                    .foregroundStyle(AppTheme.inkSecondary)
            }

            Button(action: confirmAll) {
                Text("confirm all")
                    .font(AppTypography.figureLabel())
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .background(AppTheme.accent, in: Capsule())
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private func confirmAll() {
        withAnimation(.snappy) {
            for draft in drafts {
                draft.isConfirmed = true
            }
        }
        try? modelContext.save()
        WidgetRefresh.now()
    }
}
