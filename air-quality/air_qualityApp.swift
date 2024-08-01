import SwiftUI

@main
struct MenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    let locationViewModel = LocationViewModel()
    var eventMonitor: Any?
    var aboutWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let statusButton = statusItem?.button {
            statusButton.image = NSImage(systemSymbolName: "leaf.fill", accessibilityDescription: "Air Quality")
            statusButton.action = #selector(togglePopover)
        }
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: ContentView(viewModel: locationViewModel, showAboutWindow: showAboutWindow))
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popover?.isShown == true {
                strongSelf.closePopover(event)
            }
        }
        
        setupAboutWindow()
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                closePopover(sender)
            } else {
                locationViewModel.refreshData()
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                
                // Activate the app immediately after showing the popover
                DispatchQueue.main.async {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
            }
        }
    }
    
    func closePopover(_ sender: Any?) {
        popover?.performClose(sender)
    }
    
    func setupAboutWindow() {
        aboutWindow = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 400, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        aboutWindow?.title = "Air Quality"
        aboutWindow?.center()
        aboutWindow?.contentView = NSHostingView(rootView: AirQualityInfoView	())
        aboutWindow?.isReleasedWhenClosed = false
    }
    
    func showAboutWindow() {
        if aboutWindow?.isVisible == true {
            aboutWindow?.makeKeyAndOrderFront(nil)
        } else {
            aboutWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
}
