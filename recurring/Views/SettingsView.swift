//
//  SettingsView.swift
//  recurring
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppConstants.notificationsEnabledKey) private var notificationsEnabled = true
    @State private var contentHeight: CGFloat = 0
    @State private var chromeHeight: CGFloat = 0

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("renewal notifications on this device", isOn: $notificationsEnabled)
                    .font(AppTypography.figureLabel())
                    .tint(AppTheme.accent)
                    .onChange(of: notificationsEnabled) { _, _ in
                        Task { await NotificationScheduler.rescheduleAll(context: modelContext) }
                    }

                Text("Lead time is set on each subscription. Other devices stay quiet until you turn notifications on there.")
                    .font(AppTypography.meta())
                    .foregroundStyle(AppTheme.inkSecondary)
            }
            .appCard()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newValue in
                // The first layout pass is only as wide as the text's ideal width,
                // which wraps this copy to a near full-screen height and then snaps down.
                guard newValue.width >= 280 else { return }
                FittedSheet.assign($contentHeight, to: newValue.height)
            }
            .background {
                SheetChromeReader { newValue in
                    FittedSheet.assign($chromeHeight, to: newValue)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .screenCanvas()
            .navigationTitle("notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(FittedSheet.height(content: contentHeight, chrome: chromeHeight))])
    }
}
