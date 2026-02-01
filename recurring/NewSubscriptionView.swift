//
//  NewSubscriptionView.swift
//  recurring
//
//  Created by Tristan Chay on 2/2/26.
//

import SwiftUI
import SwiftData

struct NewSubscriptionView: View {

    @State private var subscriptionName = ""
    @State private var subscriptionPrice = 0.0
    @State private var subscriptionDate = Date()
    @State private var subscriptionOccurence: Subscription.Occurence = .monthly

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("name", text: $subscriptionName)
                    TextField("price", text: Binding(get: {
                        "\(subscriptionPrice)"
                    }, set: { value in
                        subscriptionPrice = Double(value) ?? 0.0
                    }))
                    .keyboardType(.decimalPad)

                    DatePicker("renewal date", selection: Binding(get: {
                        Calendar.current.startOfDay(for: subscriptionDate)
                    }, set: { value in
                        subscriptionDate = Calendar.current.startOfDay(for: value)
                    }), displayedComponents: .date)

                    Picker("occurence", selection: $subscriptionOccurence) {
                        ForEach(Subscription.Occurence.allCases, id: \.hashValue) { occurence in
                            Text(occurence.rawValue)
                                .tag(occurence)
                        }
                    }
                }
            }
            .navigationTitle("new subscription")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        modelContext.insert(
                            Subscription(
                                name: subscriptionName,
                                startDate: subscriptionDate,
                                occurence: subscriptionOccurence,
                                price: subscriptionPrice
                            )
                        )
                        dismiss()
                    } label: {
                        Label("add subscription", systemImage: "checkmark")
                    }
                    .buttonStyle(.glassProminent)
                }
            }
        }
    }
}

#Preview {
    NewSubscriptionView()
}
