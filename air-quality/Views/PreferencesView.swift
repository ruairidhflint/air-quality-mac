import ServiceManagement
import SwiftUI

struct PreferencesView: View {
    @ObservedObject var viewModel: AirQualityViewModel
    @State private var launchAtLogin = false
    @State private var launchError: String?

    var body: some View {
        Form {
            Section("Air quality alerts") {
                Toggle("Notify when AQI exceeds threshold", isOn: $viewModel.alertsEnabled)
                    .onChange(of: viewModel.alertsEnabled) { _, on in
                        if on {
                            viewModel.requestNotificationAuthorizationIfNeeded()
                        }
                    }
                Stepper(value: $viewModel.alertThresholdAQI, in: 0...500, step: 10) {
                    Text("Threshold: US AQI \(viewModel.alertThresholdAQI)")
                }
                Text("You’ll get a notification when the index rises to or above the threshold (after being below it).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Startup") {
                Toggle("Launch Oxygenie at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        setLaunchAtLogin(enabled)
                    }
                if let launchError {
                    Text(launchError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("About") {
                LabeledContent("Version") {
                    Text(Bundle.main.shortVersionString)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 320)
        .onAppear {
            launchAtLogin = Self.readLaunchAtLoginStatus()
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        launchError = nil
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                launchAtLogin = Self.readLaunchAtLoginStatus()
            } catch {
                launchError = error.localizedDescription
                launchAtLogin = Self.readLaunchAtLoginStatus()
            }
        } else {
            launchError = "Requires macOS 13 or later."
            launchAtLogin = false
        }
    }

    private static func readLaunchAtLoginStatus() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
}

private extension Bundle {
    var shortVersionString: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "—"
    }
}
