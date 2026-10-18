//
//  DraftChargeRow.swift
//  recurring
//

import SwiftData
import SwiftUI

struct DraftChargeRow: View {
    @Bindable var draft: Charge
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(draft.date.formatted(date: .abbreviated, time: .omitted))
                    .font(AppTypography.figureLabel())
                Text("draft")
                    .font(AppTypography.meta())
                    .foregroundStyle(AppTheme.inkSecondary)
            }

            Spacer()

            TextField("amount", value: $draft.sgdAmount, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.moneyCaption())
                .frame(maxWidth: 100)

            Button {
                draft.isConfirmed = true
                try? modelContext.save()
                WidgetRefresh.now()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .tint(.green)
            .accessibilityLabel("confirm")
        }
        .padding(.vertical, 10)
    }
}
