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
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(draft.date.formatted(date: .abbreviated, time: .omitted))
                .font(AppTypography.figureLabel())
                .lineLimit(1)
                .layoutPriority(1)

            Spacer(minLength: 8)

            TextField(
                "0",
                value: $draft.sgdAmount,
                format: .currency(code: "SGD")
            )
            .textFieldStyle(.plain)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .font(.moneyCaption())
            .foregroundStyle(AppTheme.accent)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: 120)
            .accessibilityLabel("SGD charged")

            Button(action: confirm) {
                Text("confirm")
                    .font(AppTypography.figureLabel())
                    .foregroundStyle(AppTheme.accent)
            }
            .buttonStyle(.plain)
            .fixedSize()
        }
    }

    private func confirm() {
        withAnimation(.snappy) {
            draft.isConfirmed = true
        }
        try? modelContext.save()
        WidgetRefresh.now()
    }
}
