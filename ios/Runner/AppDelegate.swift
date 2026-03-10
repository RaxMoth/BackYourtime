import Flutter
import UIKit
import FamilyControls

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    private let screenTimeChannel = ScreenTimeChannel()
    private var pickerChannel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

        let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ScreenTimePlugin")!
        screenTimeChannel.register(with: registrar)

        pickerChannel = FlutterMethodChannel(
            name: "com.maxroth.backyourtime/apppicker",
            binaryMessenger: registrar.messenger()
        )
        pickerChannel?.setMethodCallHandler { [weak self] call, result in
            if call.method == "showPicker" {
                self?.showAppPicker(result: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func showAppPicker(result: @escaping FlutterResult) {
        let rootVC: UIViewController? = window?.rootViewController
            ?? UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController
        guard let rootVC else {
            result(FlutterError(code: "NO_ROOT_VC", message: nil, details: nil))
            return
        }
        let pickerVC = AppPickerViewController()
        pickerVC.onSelectionSaved = { result(true) }
        pickerVC.modalPresentationStyle = .formSheet
        rootVC.present(pickerVC, animated: true)
    }
}
