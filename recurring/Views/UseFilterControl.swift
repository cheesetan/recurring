//
//  UseFilterControl.swift
//  recurring
//

import SwiftUI

struct UseFilterControl: View {
    @Binding var filter: UseFilter

    var body: some View {
        GlassEffectContainer {
            HStack {
                ForEach(UseFilter.allCases) { option in
                    filterButton(option)
                }
            }
        }
    }

    private func filterButton(_ option: UseFilter) -> some View {
        let isSelected = filter == option
        return Button {
            withAnimation(.smooth) {
                filter = option
            }
        } label: {
            Text(option.label)
                .font(AppTypography.figureLabel())
                .padding(4)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.glass(isSelected ? .regular.tint(AppTheme.accent).interactive() : .regular.interactive()))
    }
}
