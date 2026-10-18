//
//  RootTabView.swift
//  recurring
//

import SwiftUI

struct RootTabView: View {
    @State private var useFilter: UseFilter = .all

    var body: some View {
        NavigationStack {
            UpcomingView(useFilter: $useFilter)
        }
        .tint(.accentColor)
    }
}
