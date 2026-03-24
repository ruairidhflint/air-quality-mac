import CoreLocation
import Foundation

/// Thin wrapper around `CLLocationManager` with main-thread callbacks.
final class LocationService: NSObject, CLLocationManagerDelegate {
    var onAuthorizationChange: (() -> Void)?
    var onLocation: ((Result<CLLocation, Error>) -> Void)?

    private let manager = CLLocationManager()
    private let maxLocationAge: TimeInterval = 600 // 10 minutes — reject very stale fixes

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onAuthorizationChange?()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        if abs(location.timestamp.timeIntervalSinceNow) > maxLocationAge {
            AppLogger.location.info("Ignoring stale location (age > \(self.maxLocationAge, privacy: .public)s)")
            return
        }
        onLocation?(.success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onLocation?(.failure(error))
    }
}
