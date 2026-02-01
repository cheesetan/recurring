//
//  EditSubscriptionView.swift
//  recurring
//
//  Created by Tristan Chay on 2/2/26.
//

import SwiftUI
import SwiftData

struct EditSubscriptionView: View {
    @Bindable var subscription: Subscription

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("name") {
                        TextField("iCloud+", text: $subscription.name)
                            .multilineTextAlignment(.trailing)
                    }

                    LabeledContent("price") {
                        TextField("$0.00", value: $subscription.price, format: .currency(code: "SGD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    DatePicker("renewal date", selection: Binding(get: {
                        Calendar.current.startOfDay(for: subscription.startDate)
                    }, set: { value in
                        subscription.startDate = Calendar.current.startOfDay(for: value)
                    }), displayedComponents: .date)

                    Picker("occurence", selection: $subscription.occurence) {
                        ForEach(Subscription.Occurence.allCases, id: \.hashValue) { occurence in
                            Text(occurence.rawValue)
                                .tag(occurence)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("edit subscription")
        }
    }
}

#Preview {
    NewSubscriptionView()
}
