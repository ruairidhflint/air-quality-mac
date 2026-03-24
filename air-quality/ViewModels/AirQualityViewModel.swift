import Combine
import CoreLocation
import Foundation
import UserNotifications

@MainActor
final class AirQualityViewModel: ObservableObject {
    @Published private(set) var locationName: String?
    /// User-facing status (errors, hints). Empty when OK.
    @Published private(set) var statusMessage: String = ""
    @Published private(set) var airQualityData: CurrentAirQuality?
    @Published private(set) var isLoading = false
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var hourlyPoints: [AQIDataPoint] = []

    @Published var alertsEnabled: Bool {
        didSet { UserDefaults.standard.set(alertsEnabled, forKey: Keys.alertsEnabled) }
    }

    @Published var alertThresholdAQI: Int {
        didSet { UserDefaults.standard.set(alertThresholdAQI, forKey: Keys.alertThreshold) }
    }

    /// Called when menu bar title/color should refresh (AQI, loading).
    var onMenuBarStateChanged: (() -> Void)?

    private let locationService = LocationService()
    private let airQualityService = AirQualityService()
    private let cache = AirQualityCache()
    private let geocoder = CLGeocoder()

    private var locationRetryCount = 0
    private let maxLocationRetries = 3
    private var isLocationFetchActive = false
    private var consumedLocationThisSession = false

    private var refreshTimer: Timer?
    private var lastAQIWasBelowThreshold = true

    private var inflightFetch: Task<Void, Never>?

    private enum Keys {
        static let alertsEnabled = "oxygenie.alertsEnabled"
        static let alertThreshold = "oxygenie.alertThresholdAQI"
    }

    init() {
        self.alertsEnabled = UserDefaults.standard.object(forKey: Keys.alertsEnabled) as? Bool ?? false
        let stored = UserDefaults.standard.object(forKey: Keys.alertThreshold) as? Int
        self.alertThresholdAQI = stored ?? 100
        wireLocationService()
        loadCachedSnapshot()
        startPeriodicRefresh()
    }

    deinit {
        refreshTimer?.invalidate()
        inflightFetch?.cancel()
    }

    func loadCachedSnapshot() {
        guard let snap = cache.load() else { return }
        airQualityData = snap.current
        locationName = snap.locationName
        lastUpdated = snap.lastUpdated
        hourlyPoints = snap.hourlyPoints.map(\.asPoint)
        onMenuBarStateChanged?()
    }

    /// User opened popover or tapped Refresh — full spinner + location if needed.
    func refreshData() {
        inflightFetch?.cancel()
        consumedLocationThisSession = false
        beginUserInitiatedRefresh()
    }

    /// Skip hitting GPS/network if we already have a recent reading (e.g. opening the popover).
    func refreshDataIfStale(maxAge: TimeInterval = 15 * 60) {
        if let last = lastUpdated, Date().timeIntervalSince(last) < maxAge {
            onMenuBarStateChanged?()
            return
        }
        refreshData()
    }

    /// Background timer: re-fetch using cached coordinates when available.
    func refreshIfPossible() {
        guard let snap = cache.load(), let lat = snap.latitude, let lon = snap.longitude else {
            return
        }
        inflightFetch?.cancel()
        inflightFetch = Task { [weak self] in
            await self?.performNetworkFetch(latitude: lat, longitude: lon, showLoadingInMenuBar: true, clearLocationSession: false)
        }
    }

    private func wireLocationService() {
        locationService.onAuthorizationChange = { [weak self] in
            Task { @MainActor in
                self?.handleAuthorizationChange()
            }
        }
        locationService.onLocation = { [weak self] result in
            Task { @MainActor in
                self?.handleLocationResult(result)
            }
        }
    }

    private func handleAuthorizationChange() {
        switch locationService.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if isLocationFetchActive, !consumedLocationThisSession {
                locationService.startUpdatingLocation()
            }
        case .denied, .restricted:
            statusMessage = "Location access denied. Enable in System Settings → Privacy & Security → Location Services."
            isLoading = false
            isLocationFetchActive = false
        case .notDetermined:
            break
        @unknown default:
            statusMessage = "Unknown location authorization."
            isLoading = false
        }
        onMenuBarStateChanged?()
    }

    private func beginUserInitiatedRefresh() {
        statusMessage = ""
        isLoading = true
        isLocationFetchActive = true
        locationRetryCount = 0
        consumedLocationThisSession = false
        onMenuBarStateChanged?()

        guard CLLocationManager.locationServicesEnabled() else {
            statusMessage = "Location services are disabled on this Mac."
            isLoading = false
            isLocationFetchActive = false
            onMenuBarStateChanged?()
            return
        }

        switch locationService.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationService.startUpdatingLocation()
        case .denied, .restricted:
            statusMessage = "Location access denied. Enable in System Settings."
            isLoading = false
            isLocationFetchActive = false
            onMenuBarStateChanged?()
        case .notDetermined:
            locationService.requestWhenInUseAuthorization()
        @unknown default:
            statusMessage = "Unknown location authorization."
            isLoading = false
            isLocationFetchActive = false
            onMenuBarStateChanged?()
        }
    }

    private func handleLocationResult(_ result: Result<CLLocation, Error>) {
        guard isLocationFetchActive, !consumedLocationThisSession else { return }

        switch result {
        case .success(let location):
            consumedLocationThisSession = true
            locationService.stopUpdatingLocation()
            statusMessage = "Fetching air quality…"
            reverseGeocode(location: location)
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            inflightFetch?.cancel()
            inflightFetch = Task { [weak self] in
                await self?.performNetworkFetch(latitude: lat, longitude: lon, showLoadingInMenuBar: true, clearLocationSession: true)
            }

        case .failure(let error):
            let ns = error as NSError
            if ns.domain == kCLErrorDomain, ns.code == CLError.locationUnknown.rawValue {
                AppLogger.location.warning("Temporary location error, retrying…")
                retryLocationRequest()
            } else {
                statusMessage = "Location error: \(error.localizedDescription)"
                isLoading = false
                isLocationFetchActive = false
                AppLogger.location.error("Location failed: \(error.localizedDescription, privacy: .public)")
                onMenuBarStateChanged?()
            }
        }
    }

    private func retryLocationRequest() {
        guard locationRetryCount < maxLocationRetries else {
            statusMessage = "Unable to determine location after several attempts."
            isLoading = false
            isLocationFetchActive = false
            onMenuBarStateChanged?()
            return
        }
        locationRetryCount += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.locationService.startUpdatingLocation()
        }
    }

    private func reverseGeocode(location: CLLocation) {
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    AppLogger.location.warning("Geocode failed: \(error.localizedDescription, privacy: .public)")
                    return
                }
                guard let placemark = placemarks?.first else { return }
                let name = [placemark.name, placemark.locality, placemark.administrativeArea, placemark.country]
                    .compactMap { $0 }
                    .joined(separator: ", ")
                self.locationName = name
            }
        }
    }

    private func performNetworkFetch(latitude: Double, longitude: Double, showLoadingInMenuBar: Bool, clearLocationSession: Bool) async {
        if showLoadingInMenuBar {
            await MainActor.run {
                self.isLoading = true
                self.onMenuBarStateChanged?()
            }
        }

        defer {
            Task { @MainActor in
                if clearLocationSession {
                    self.isLocationFetchActive = false
                }
                self.isLoading = false
                self.onMenuBarStateChanged?()
            }
        }

        do {
            let result = try await airQualityService.fetchAirQuality(latitude: latitude, longitude: longitude)
            await MainActor.run {
                if Task.isCancelled { return }
                self.airQualityData = result.current
                self.hourlyPoints = result.hourly
                self.lastUpdated = Date()
                self.statusMessage = ""
                self.persistCache(current: result.current, hourly: result.hourly, latitude: latitude, longitude: longitude)
                self.evaluateNotificationIfNeeded(aqi: result.current.usAQI)
            }
        } catch {
            await MainActor.run {
                if Task.isCancelled { return }
                if let aq = error as? AirQualityError {
                    self.statusMessage = aq.localizedDescription
                } else {
                    self.statusMessage = error.localizedDescription
                }
                AppLogger.network.error("Air quality fetch failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func persistCache(current: CurrentAirQuality, hourly: [AQIDataPoint], latitude: Double, longitude: Double) {
        let snap = AirQualityCache.Snapshot(
            current: current,
            locationName: locationName,
            lastUpdated: Date(),
            hourlyPoints: hourly.map { AirQualityCache.AQIDataPointCodable(point: $0) },
            latitude: latitude,
            longitude: longitude
        )
        cache.save(snap)
    }

    private func startPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshIfPossible()
            }
        }
        if let refreshTimer {
            RunLoop.main.add(refreshTimer, forMode: .common)
        }
    }

    private func evaluateNotificationIfNeeded(aqi: Int) {
        guard alertsEnabled else {
            lastAQIWasBelowThreshold = aqi < alertThresholdAQI
            return
        }
        let above = aqi >= alertThresholdAQI
        if above, lastAQIWasBelowThreshold {
            lastAQIWasBelowThreshold = false
            sendThresholdNotification(aqi: aqi)
        } else if !above {
            lastAQIWasBelowThreshold = true
        }
    }

    private func sendThresholdNotification(aqi: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Air quality alert"
        content.body = "US AQI is \(aqi) (threshold \(alertThresholdAQI)). \(AQICategory.category(forUSAQI: aqi).displayName)."
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                AppLogger.notifications.error("Failed to post notification: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func requestNotificationAuthorizationIfNeeded() {
        guard alertsEnabled else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                AppLogger.notifications.error("Notification auth error: \(error.localizedDescription, privacy: .public)")
            } else {
                AppLogger.notifications.info("Notification permission granted: \(granted, privacy: .public)")
            }
        }
    }
}
