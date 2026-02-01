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
        NavigationStack {
            VStack {
                if subscriptions.isEmpty {
                    ContentUnavailableView("no subscriptions", systemImage: "singaporedollarsign.arrow.trianglehead.counterclockwise.rotate.90", description: Text("you have no active subscriptions. add one to get started."))
                } else {
                    List {
                        Section {
                            VStack(alignment: .leading) {
                                Text("total: $\(subscriptions.map({ $0.totalPricePerYear }).reduce(0, +), specifier: "%.2f")")
                                    .font(.headline)
                                Text("per year")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        ForEach(subscriptions.sorted{ $0.name < $1.name }.sorted { $0.renewalDate < $1.renewalDate }) { subscription in
                            NavigationLink {
                                EditSubscriptionView(subscription: subscription)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(subscription.name)
                                            .font(.headline)
                                        Text(subscription.renewalDate.formatted(date: .abbreviated, time: .omitted))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("$\(subscription.price, specifier: "%.2f")/\(subscription.occurence.short)")
                                }
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
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
