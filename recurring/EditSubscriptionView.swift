//
//  EditSubscriptionView.swift
//  recurring
//
//  Created by Tristan Chay on 2/2/26.
//

import SwiftUI
import SwiftData

struct EditSubscriptionView: View {

    @State private var priceText = "0.00"
    @FocusState private var isFocused: Bool

    @Bindable var subscription: Subscription

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("name", text: $subscription.name)
                    TextField("price", text: $priceText)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                        .onChange(of: priceText) {
                            handleInput(priceText)
                        }
                        .onChange(of: isFocused) {
                            if !isFocused {
                                formatTo2DP()
                            } else {
                                if priceText == "0.00" {
                                    priceText = ""
                                    return
                                }
                            }
                        }
                        .onAppear {
                            priceText = "\(subscription.price)"
                            formatTo2DP()
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
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("new subscription")
        }
    }

    private func handleInput(_ input: String) {
        var filtered = input.filter { "0123456789.".contains($0) }

        let decimalCount = filtered.filter { $0 == "." }.count
        if decimalCount > 1 {
            filtered.removeLast()
        }

        if let dotIndex = filtered.firstIndex(of: ".") {
            let decimals = filtered.distance(from: dotIndex, to: filtered.endIndex) - 1
            if decimals > 2 {
                filtered.removeLast()
            }
        }

        priceText = filtered
        subscription.price = Double(filtered) ?? 0.0
    }

    private func formatTo2DP() {
        subscription.price = Double(priceText) ?? 0.0
        priceText = String(format: "%.2f", subscription.price)
    }

}

#Preview {
    NewSubscriptionView()
}
