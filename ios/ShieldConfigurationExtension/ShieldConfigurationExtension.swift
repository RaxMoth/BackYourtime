import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private let sharedDefaults = UserDefaults(suiteName: "group.com.maxroth.backyourtime")

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return buildConfig(appName: application.localizedDisplayName)
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return buildConfig(appName: application.localizedDisplayName)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return buildConfig(appName: webDomain.domain ?? "Website")
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return buildConfig(appName: webDomain.domain ?? "Website")
    }

    private func buildConfig(appName: String?) -> ShieldConfiguration {
        let profileName = sharedDefaults?.string(forKey: "activeProfileName") ?? "Focus"

        return ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterial,
            backgroundColor: UIColor.black.withAlphaComponent(0.85),
            icon: UIImage(systemName: "shield.checkered"),
            title: ShieldConfiguration.Label(
                text: "\(appName ?? "App") is blocked",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Blocked by \"\(profileName)\" in Unspend",
                color: .systemGray
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Go Back",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor.systemBlue,
            secondaryButtonLabel: nil
        )
    }
}
