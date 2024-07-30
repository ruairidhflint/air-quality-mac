import SwiftUI
import CoreLocation
import MapKit


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
    @Published var status: String = "Fetching location and air quality..."
    @Published var airQualityData: CurrentAirQuality?
    @Published var isLoading: Bool = false
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var locationRetryCount = 0
    private let maxLocationRetries = 3
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func refreshData() {
        requestLocation()
    }
    
    private func requestLocation() {
        status = "Fetching location..."
        locationRetryCount = 0
        isLoading = true
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            checkLocationAuthorization()
        } else {
            status = "Location services are disabled"
            isLoading = false
        }
    }
    
    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            status = "Location access denied. Please enable in Settings."
            isLoading = false
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            status = "Unknown authorization status"
            isLoading = false
        }
    }
    
    private func retryLocationRequest() {
        guard locationRetryCount < maxLocationRetries else {
            status = "Unable to fetch location after several attempts. Please try again later."
            isLoading = false
            return
        }
        
        locationRetryCount += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.locationManager.startUpdatingLocation()
        }
    }
    
    func fetchAirQuality(latitude: Double, longitude: Double) {
        let urlString = "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=\(latitude)&longitude=\(longitude)&current=european_aqi,pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone"
        
        guard let url = URL(string: urlString) else {
            status = "Invalid URL"
            isLoading = false
            return
        }
        
        print("Fetching air quality for latitude: \(latitude), longitude: \(longitude)")
        print("URL: \(urlString)")
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
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
            if (error as NSError).code == 0 && (error as NSError).domain == kCLErrorDomain {
                print("Temporary location error, retrying...")
                self.retryLocationRequest()
            } else {
                self.status = "Error: \(error.localizedDescription)"
                self.isLoading = false
                print("Location error: \(error)")
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}


