import UIKit
import SwiftUI
import FamilyControls
import Foundation

class AppPickerViewController: UIViewController {
    var onSelectionSaved: ((Int) -> Void)?
    private let sharedDefaults = UserDefaults(suiteName: "group.com.maxroth.backyourtime")!

    override func viewDidLoad() {
        super.viewDidLoad()
        let pickerView = AppPickerView(onSave: { [weak self] selection in
            let count = selection.applicationTokens.count
                + selection.categoryTokens.count
                + selection.webDomainTokens.count
            if let data = try? JSONEncoder().encode(selection) {
                self?.sharedDefaults.set(data, forKey: "blockedApps")
            }
            self?.dismiss(animated: true) {
                self?.onSelectionSaved?(count)
            }
        }, onCancel: { [weak self] in
            self?.dismiss(animated: true)
        })
        let hostingController = UIHostingController(rootView: pickerView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        hostingController.didMove(toParent: self)
    }
}

private struct AppPickerView: View {
    @State private var selection = FamilyActivitySelection()
    var onSave: (FamilyActivitySelection) -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationView {
            VStack {
                FamilyActivityPicker(selection: $selection)
            }
            .navigationTitle("Choose Apps")
            .navigationBarTitleDisplayMode(.inline)
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
    }
}
