//
//  ContentView.swift
//  recurring
//
//  Created by Tristan Chay on 2/2/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @State private var showingAddSubscriptionView = false

    @Environment(\.modelContext) private var modelContext
    @Query private var subscriptions: [Subscription]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(subscriptions) { subscription in
                    VStack(alignment: .leading) {
                        Text(subscription.name)
                            .font(.headline)
                        Text(subscription.renewalDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("recurring")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem {
                    Button {
                        showingAddSubscriptionView.toggle()
                    } label: {
                        Label("add subscription", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("select a subscription")
        }
        .sheet(isPresented: $showingAddSubscriptionView) {
            NewSubscriptionView()
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(subscriptions[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
