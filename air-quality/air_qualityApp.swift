import AppKit
import Combine
import SwiftUI
import UserNotifications

@main
struct MenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            Group {
                if let vm = appDelegate.viewModel {
                    PreferencesView(viewModel: vm)
                } else {
                    ProgressView()
                        .padding()
                }
            }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var viewModel: AirQualityViewModel!

    private var statusItem: NSStatusItem!
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private var aboutWindow: NSWindow?
    private var welcomeWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    private static let hasLaunchedBeforeKey = "oxygenie.hasLaunchedBefore"

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLogger.general.info("applicationDidFinishLaunching — starting setup")

        viewModel = AirQualityViewModel()

        NSSetUncaughtExceptionHandler { exception in
            AppLogger.general.critical("Uncaught NSException: \(exception.reason ?? "unknown", privacy: .public)")
        }

        UNUserNotificationCenter.current().delegate = self

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "AQI"
            button.contentTintColor = .systemGreen
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .bold)
            button.target = self
            button.action = #selector(togglePopover)
            button.toolTip = "Oxygenie — air quality"
            AppLogger.general.info("Status item created, button exists")
        } else {
            AppLogger.general.error("Status item button is nil!")
        }

        viewModel.onMenuBarStateChanged = { [weak self] in
            self?.updateStatusItem()
        }

        Publishers.CombineLatest3(viewModel.$airQualityData, viewModel.$isLoading, viewModel.$statusMessage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _, _ in
                self?.updateStatusItem()
            }
            .store(in: &cancellables)

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 360, height: 560)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: ContentView(viewModel: viewModel, showAboutWindow: { [weak self] in
                self?.showAboutWindow()
            })
        )

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, self.popover?.isShown == true else { return }
            self.closePopover(event)
        }

        setupAboutWindow()

        AppLogger.general.info("Setup complete — status item visible in the menu bar")

        if !UserDefaults.standard.bool(forKey: Self.hasLaunchedBeforeKey) {
            showWelcomeWindow()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.viewModel.refreshIfPossible()
        }
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        if popover?.isShown == true {
            closePopover(sender)
        } else {
            viewModel.refreshDataIfStale()
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            DispatchQueue.main.async {
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
    }

    func closePopover(_ sender: Any?) {
        popover?.performClose(sender)
    }

    private func setupAboutWindow() {
        aboutWindow = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 400, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        aboutWindow?.title = "Oxygenie"
        aboutWindow?.center()
        aboutWindow?.contentView = NSHostingView(rootView: AirQualityInfoView())
        aboutWindow?.isReleasedWhenClosed = false
    }

    func showAboutWindow() {
        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showWelcomeWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Oxygenie"
        window.center()
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(
            rootView: WelcomeView { [weak self] in
                UserDefaults.standard.set(true, forKey: Self.hasLaunchedBeforeKey)
                window.close()
                self?.viewModel.refreshData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.togglePopover(nil)
                }
            }
        )
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        welcomeWindow = window
    }

    private func updateStatusItem() {
        guard let button = statusItem.button else { return }
        if viewModel.isLoading {
            statusItem.length = NSStatusItem.variableLength
            button.image = nil
            button.attributedTitle = NSAttributedString(
                string: "…",
                attributes: [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium),
                    .foregroundColor: NSColor.white.withAlphaComponent(0.6)
                ]
            )
        } else if let aqi = viewModel.airQualityData?.usAQI {
            statusItem.length = NSStatusItem.variableLength
            button.image = nil
            button.attributedTitle = NSAttributedString(
                string: "\(aqi)",
                attributes: [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold),
                    .foregroundColor: NSColor.oxygenieAQI(forUSAQI: aqi)
                ]
            )
        } else {
            statusItem.length = NSStatusItem.squareLength
            button.attributedTitle = NSAttributedString(string: "")
            let img = NSImage(systemSymbolName: "leaf.fill", accessibilityDescription: "Air quality")
            img?.isTemplate = true
            button.image = img
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
