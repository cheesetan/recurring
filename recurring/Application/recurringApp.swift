//
//  recurringApp.swift
//  recurring
//

import SwiftData
import SwiftUI
import UIKit

@main
struct recurringApp: App {
    let container: ModelContainer

    init() {
        Self.configureRoundedNavigationBar()
        if UserDefaults.standard.object(forKey: AppConstants.notificationsEnabledKey) == nil {
            UserDefaults.standard.set(true, forKey: AppConstants.notificationsEnabledKey)
        }
        do {
            container = try ModelContainerProvider.makeShared()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .fontDesign(.rounded)
                .tint(AppTheme.accent)
                .scrollEdgeEffectStyle(.soft, for: .top)
                .task {
                    await NotificationScheduler.requestAuthorizationIfNeeded()
                }
                .onAppear {
                    let context = container.mainContext
                    try? ChargeRecorder.processDueCharges(context: context)
                    WidgetRefresh.now()
                    Task { await NotificationScheduler.rescheduleAll(context: context) }
                }
        }
        .modelContainer(container)
    }

    private static func configureRoundedNavigationBar() {
        func rounded(size: CGFloat, weight: UIFont.Weight) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
            return UIFont(descriptor: descriptor, size: size)
        }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [.font: rounded(size: 17, weight: .semibold)]
        appearance.largeTitleTextAttributes = [.font: rounded(size: 34, weight: .bold)]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}
