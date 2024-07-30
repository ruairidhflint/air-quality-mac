import SwiftUI
import CoreLocation
import MapKit

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
            statusButton.image = NSImage(systemSymbolName: "aqi.medium", accessibilityDescription: "Air Quality")
            statusButton.action = #selector(togglePopover)
        }
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 400)
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

struct AirQualityData: Codable {
    let current: CurrentAirQuality
}

struct CurrentAirQuality: Codable {
    let europeanAQI: Int
    let pm10: Double
    let pm2_5: Double
    let carbonMonoxide: Double
    let nitrogenDioxide: Double
    let sulphurDioxide: Double
    let ozone: Double
    
    enum CodingKeys: String, CodingKey {
        case europeanAQI = "european_aqi"
        case pm10, pm2_5
        case carbonMonoxide = "carbon_monoxide"
        case nitrogenDioxide = "nitrogen_dioxide"
        case sulphurDioxide = "sulphur_dioxide"
        case ozone
    }
}

class LocationViewModel: NSObject, ObservableObject {
    @Published var locationName: String?
    @Published var status: String = "Tap to fetch location and air quality"
    @Published var airQualityData: CurrentAirQuality?
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestLocation() {
        status = "Fetching location..."
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        } else {
            status = "Location services are disabled"
        }
    }
    
    func fetchAirQuality(latitude: Double, longitude: Double) {
        let urlString = "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=\(latitude)&longitude=\(longitude)&current=european_aqi,pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone"
        
        guard let url = URL(string: urlString) else {
            status = "Invalid URL"
            return
        }
        
        print("Fetching air quality for latitude: \(latitude), longitude: \(longitude)")
        print("URL: \(urlString)")
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.status = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    self?.status = "Server error"
                    return
                }
                
                guard let data = data else {
                    self?.status = "No data received"
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let airQualityResponse = try decoder.decode(AirQualityData.self, from: data)
                    self?.airQualityData = airQualityResponse.current
                    self?.status = ""
                } catch {
                    self?.status = "Error decoding data: \(error.localizedDescription)"
                }
            }
        }
        print("Starting network request")
        task.resume()
    }
    
    func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.status = "Geocoding error: \(error.localizedDescription)"
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    self?.status = "No placemark found"
                    return
                }
                
                let name = [placemark.name, placemark.locality, placemark.administrativeArea, placemark.country]
                    .compactMap { $0 }
                    .joined(separator: ", ")
                
                self?.locationName = name
            }
        }
    }
}

extension LocationViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.status = "Location updated, fetching air quality..."
            self.reverseGeocode(location: location)
            self.fetchAirQuality(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
        locationManager.stopUpdatingLocation()
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
            manager.startUpdatingLocation()
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
        VStack(alignment: .leading, spacing: 10) {            
            Text(viewModel.status)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let locationName = viewModel.locationName {
                Text("\(locationName)")
                    .font(.headline)
            }
            
            if let airQuality = viewModel.airQualityData {
                Text("Air Quality Index: \(airQuality.europeanAQI)")
                    .font(.headline)
                    .padding(.top)
                Text("PM10: \(airQuality.pm10, specifier: "%.2f") µg/m³")
                Text("PM2.5: \(airQuality.pm2_5, specifier: "%.2f") µg/m³")
                Text("Carbon Monoxide: \(airQuality.carbonMonoxide, specifier: "%.2f") µg/m³")
                Text("Nitrogen Dioxide: \(airQuality.nitrogenDioxide, specifier: "%.2f") µg/m³")
                Text("Sulphur Dioxide: \(airQuality.sulphurDioxide, specifier: "%.2f") µg/m³")
                Text("Ozone: \(airQuality.ozone, specifier: "%.2f") µg/m³")
            }
            
            Spacer()
            
            Button("Refresh Data") {
                viewModel.requestLocation()
            }
            .padding(.top)
        }
        .frame(width: 300, height: 400)
        .padding()
    }
}
