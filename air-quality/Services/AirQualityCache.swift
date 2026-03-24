import Foundation

/// Persists last-known good reading so the UI is never empty on launch.
final class AirQualityCache {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Keys {
        static let snapshot = "airQuality.cachedSnapshot"
    }

    struct Snapshot: Codable, Equatable {
        var current: CurrentAirQuality
        var locationName: String?
        var lastUpdated: Date
        var hourlyPoints: [AQIDataPointCodable]
        /// Last coordinates used for API fetch (enables background refresh without GPS).
        var latitude: Double?
        var longitude: Double?
    }

    /// Codable wrapper for UserDefaults (UUID in AQIDataPoint is not stable across encodes).
    struct AQIDataPointCodable: Codable, Equatable {
        var date: Date
        var usAQI: Int

        init(date: Date, usAQI: Int) {
            self.date = date
            self.usAQI = usAQI
        }

        init(point: AQIDataPoint) {
            self.date = point.date
            self.usAQI = point.usAQI
        }

        var asPoint: AQIDataPoint {
            AQIDataPoint(date: date, usAQI: usAQI)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> Snapshot? {
        guard let data = defaults.data(forKey: Keys.snapshot) else { return nil }
        do {
            return try decoder.decode(Snapshot.self, from: data)
        } catch {
            AppLogger.general.error("Cache decode failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func save(_ snapshot: Snapshot) {
        do {
            let data = try encoder.encode(snapshot)
            defaults.set(data, forKey: Keys.snapshot)
        } catch {
            AppLogger.general.error("Cache encode failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
