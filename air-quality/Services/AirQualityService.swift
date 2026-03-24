import Foundation

/// Fetches current + optional hourly AQI from Open-Meteo with timeout and retries.
actor AirQualityService {
    private let session: URLSession
    private let maxRetries = 3
    private let baseDelayNanoseconds: UInt64 = 300_000_000 // 0.3s

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 15
            config.timeoutIntervalForResource = 30
            self.session = URLSession(configuration: config)
        }
    }

    /// Combined request: current pollutants + last 24h hourly US AQI for charts.
    func fetchAirQuality(latitude: Double, longitude: Double) async throws -> (current: CurrentAirQuality, hourly: [AQIDataPoint]) {
        var components = URLComponents(string: "https://air-quality-api.open-meteo.com/v1/air-quality")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(
                name: "current",
                value: "us_aqi,pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone"
            ),
            URLQueryItem(name: "hourly", value: "us_aqi"),
            URLQueryItem(name: "past_hours", value: "24")
        ]
        guard let url = components.url else {
            throw AirQualityError.invalidURL
        }

        let (data, response) = try await fetchWithRetries(url: url)
        guard let http = response as? HTTPURLResponse else {
            throw AirQualityError.noData
        }
        guard (200...299).contains(http.statusCode) else {
            throw AirQualityError.httpStatus(http.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(OpenMeteoAirQualityResponse.self, from: data)
            let current = decoded.current.asCurrentAirQuality()
            let hourly = Self.parseHourly(decoded.hourly)
            return (current, hourly)
        } catch {
            throw AirQualityError.decoding(error)
        }
    }

    private func fetchWithRetries(url: URL) async throws -> (Data, URLResponse) {
        var lastError: Error?
        for attempt in 0..<maxRetries {
            do {
                return try await session.data(from: url)
            } catch {
                lastError = error
                if let urlError = error as? URLError {
                    AppLogger.network.warning("Request failed (attempt \(attempt + 1)): \(urlError.localizedDescription, privacy: .public)")
                } else {
                    AppLogger.network.warning("Request failed (attempt \(attempt + 1)): \(error.localizedDescription, privacy: .public)")
                }
                let backoff = baseDelayNanoseconds * UInt64(1 << attempt)
                try await Task.sleep(nanoseconds: backoff)
            }
        }
        if let urlError = lastError as? URLError {
            throw AirQualityError.network(urlError)
        }
        throw lastError ?? AirQualityError.noData
    }

    private static let isoParser: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoParserNoFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let openMeteoHourlyParser: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return f
    }()

    private static func parseHourly(_ payload: HourlyUSAQIPayload?) -> [AQIDataPoint] {
        guard let payload else { return [] }
        var points: [AQIDataPoint] = []
        for (index, timeString) in payload.time.enumerated() {
            guard index < payload.usAqi.count, let raw = payload.usAqi[index], let value = Int(exactly: raw.rounded()) else { continue }
            let date = isoParser.date(from: timeString)
                ?? isoParserNoFraction.date(from: timeString)
                ?? openMeteoHourlyParser.date(from: timeString)
            guard let date else { continue }
            points.append(AQIDataPoint(date: date, usAQI: value))
        }
        return points.sorted { $0.date < $1.date }
    }
}
