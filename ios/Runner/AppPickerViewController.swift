import UIKit
import SwiftUI
import FamilyControls
import Foundation

class AppPickerViewController: UIViewController {
    var onSelectionSaved: (() -> Void)?
    private let sharedDefaults = UserDefaults(suiteName: "group.com.maxroth.backyourtime")!

    override func viewDidLoad() {
        super.viewDidLoad()
        let pickerView = AppPickerView(onSave: { [weak self] selection in
            if let data = try? JSONEncoder().encode(selection) {
                self?.sharedDefaults.set(data, forKey: "blockedApps")
            }
            self?.dismiss(animated: true) {
                self?.onSelectionSaved?()
            }
        }, onCancel: { [weak self] in
            self?.dismiss(animated: true)
        })
        let hostingController = UIHostingController(rootView: pickerView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.didMove(toParent: self)
    }
}

private struct AppPickerView: View {
    @State private var selection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    var onSave: (FamilyActivitySelection) -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Button("Select Apps to Block") {
                    isPickerPresented = true
                }
                .buttonStyle(.borderedProminent)

                if !selection.applicationTokens.isEmpty {
                    Text("\(selection.applicationTokens.count) app(s) selected")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Choose Apps")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { onSave(selection) }
                        .disabled(selection.applicationTokens.isEmpty)
                }
            }
        }
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
    }
}
