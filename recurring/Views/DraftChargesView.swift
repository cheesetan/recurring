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

    var body: some View {
        Group {
            if drafts.isEmpty {
                ContentUnavailableView("no drafts", systemImage: "checkmark.circle")
            } else {
                List {
                    Section {
                    Button("confirm all") {
                        for draft in drafts { draft.isConfirmed = true }
                        try? modelContext.save()
                        WidgetRefresh.now()
                    }
                    .font(AppTypography.rowTitle())
                        .frame(maxWidth: .infinity)
                        .listRowBackground(AppTheme.card)
                    }

                    ForEach(drafts) { draft in
                        DraftChargeRow(draft: draft)
                            .listRowBackground(AppTheme.card)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
            }
        }
        .screenCanvas()
        .navigationTitle("draft charges")
        .navigationBarTitleDisplayMode(.inline)
    }
}
