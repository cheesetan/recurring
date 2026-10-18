//
//  UseFilterControl.swift
//  recurring
//

import SwiftUI

struct UseFilterControl: View {
    @Binding var filter: UseFilter

    var body: some View {
        HStack(spacing: 8) {
            ForEach(UseFilter.allCases) { option in
                Button {
                    filter = option
                } label: {
                    Text(option.label)
                        .font(AppTypography.figureLabel())
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .background(
                            filter == option ? Color.accentColor : AppTheme.card,
                            in: Capsule()
                        )
                        .foregroundStyle(filter == option ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
