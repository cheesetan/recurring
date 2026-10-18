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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("renewal notifications on this device", isOn: $notificationsEnabled)
                        .font(AppTypography.figureLabel())
                        .tint(.accentColor)
                        .onChange(of: notificationsEnabled) { _, _ in
                            Task { await NotificationScheduler.rescheduleAll(context: modelContext) }
                        }

                    Text("Lead time is set on each subscription. Other devices stay quiet until you turn notifications on there.")
                        .font(AppTypography.meta())
                        .foregroundStyle(AppTheme.inkSecondary)
                }
                .appCard()
                .padding(16)
            }
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
    }
}
