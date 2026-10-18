//
//  FittedSheetAnimationTests.swift
//  recurringTests
//

import SwiftUI
import Testing
import UIKit
@testable import recurring

@MainActor
struct FittedSheetAnimationTests {
    @Test func fittedSheetAnimatesHeight() async throws {
        let model = ProbeModel()
        let controller = UIHostingController(rootView: ProbeRoot(model: model))
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let window = scene.map { UIWindow(windowScene: $0) } ?? UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        model.show = true
        let presented = try await waitForPresented(from: controller)
        try await Task.sleep(for: .milliseconds(700))

        let before = presentationHeight(of: presented)
        model.expanded = true

        var samples: [CGFloat] = []
        for _ in 0..<20 {
            try await Task.sleep(for: .milliseconds(20))
            samples.append(presentationHeight(of: presented))
        }

        let after = samples.last ?? before
        let intermediates = samples.filter { $0 > before + 8 && $0 + 8 < after }
        #expect(after > before + 40, "sheet grew from \(before) to \(after), samples \(samples)")
        #expect(!intermediates.isEmpty, "expected animated heights between \(before) and \(after), samples \(samples)")
    }

    private func waitForPresented(from root: UIViewController) async throws -> UIViewController {
        for _ in 0..<40 {
            if let presented = root.presentedViewController {
                return presented
            }
            try await Task.sleep(for: .milliseconds(50))
        }
        Issue.record("sheet never presented")
        throw CancellationError()
    }

    private func presentationHeight(of controller: UIViewController) -> CGFloat {
        let view = controller.view!
        return (view.layer.presentation() ?? view.layer).frame.height
    }
}

private final class ProbeModel: ObservableObject {
    @Published var show = false
    @Published var expanded = false
}

private struct ProbeRoot: View {
    @ObservedObject var model: ProbeModel

    var body: some View {
        Color.clear
            .sheet(isPresented: $model.show) {
                ProbeSheet(expanded: model.expanded)
            }
    }
}

private struct ProbeSheet: View {
    var expanded: Bool
    @State private var contentHeight: CGFloat = 0
    @State private var chromeHeight: CGFloat = 0

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("base")
                if expanded {
                    Color.red.frame(height: 140)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { newValue in
                FittedSheet.assign($contentHeight, to: newValue)
            }
            .background {
                SheetChromeReader { newValue in
                    FittedSheet.assign($chromeHeight, to: newValue)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle("probe")
            .navigationBarTitleDisplayMode(.inline)
        }
        .fittedSheetDetents(content: contentHeight, chrome: chromeHeight)
    }
}
