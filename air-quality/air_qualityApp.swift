import SwiftUI
import CoreLocation

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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let statusButton = statusItem?.button {
            statusButton.image = NSImage(systemSymbolName: "location.fill", accessibilityDescription: "Location")
            statusButton.action = #selector(togglePopover)
        }
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 300)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: ContentView(viewModel: locationViewModel))
    }
    
    @objc func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                locationViewModel.requestLocation()
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}

class LocationViewModel: NSObject, ObservableObject {
    @Published var latitude: String?
    @Published var longitude: String?
    @Published var status: String = "Tap to fetch location"
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        status = "Fetching location..."
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            status = "Location access denied. Please enable in Settings."
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        @unknown default:
            status = "Unknown authorization status"
        }
    }
}

extension LocationViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.latitude = String(format: "%.6f", location.coordinate.latitude)
            self.longitude = String(format: "%.6f", location.coordinate.longitude)
            self.status = "Location updated"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.status = "Error: \(error.localizedDescription)"
            print("Location error: \(error)")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            status = "Location access denied. Please enable in Settings."
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            status = "Unknown authorization status"
        }
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: LocationViewModel
    
    var body: some View {
        VStack {
            Text("Current Location")
                .font(.title)
                .padding()
            
            Text(viewModel.status)
                .padding()
            
            if let latitude = viewModel.latitude,
               let longitude = viewModel.longitude {
                Text("Latitude: \(latitude)")
                Text("Longitude: \(longitude)")
            }
            
            Button("Refresh Location") {
                viewModel.requestLocation()
            }
            .padding()
        }
        .frame(width: 300, height: 300)
    }
}
