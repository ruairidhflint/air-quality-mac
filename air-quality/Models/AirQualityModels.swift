import Foundation

/// Open-Meteo air quality API: `current` block (subset we use).
struct OpenMeteoAirQualityResponse: Codable {
    let current: CurrentAirQualityPayload
    let hourly: HourlyUSAQIPayload?
}

struct CurrentAirQualityPayload: Codable {
    let usAQI: Int
    let pm10: Double
    let pm2_5: Double
    let carbonMonoxide: Double
    let nitrogenDioxide: Double
    let sulphurDioxide: Double
    let ozone: Double

    enum CodingKeys: String, CodingKey {
        case usAQI = "us_aqi"
        case pm10, pm2_5
        case carbonMonoxide = "carbon_monoxide"
        case nitrogenDioxide = "nitrogen_dioxide"
        case sulphurDioxide = "sulphur_dioxide"
        case ozone
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let i = try? c.decode(Int.self, forKey: .usAQI) {
            usAQI = i
        } else if let d = try? c.decode(Double.self, forKey: .usAQI) {
            usAQI = Int(d.rounded())
        } else {
            throw DecodingError.dataCorruptedError(forKey: .usAQI, in: c, debugDescription: "Expected Int or Double for us_aqi")
        }
        pm10 = try c.decodeIfPresent(Double.self, forKey: .pm10) ?? 0
        pm2_5 = try c.decodeIfPresent(Double.self, forKey: .pm2_5) ?? 0
        carbonMonoxide = try c.decodeIfPresent(Double.self, forKey: .carbonMonoxide) ?? 0
        nitrogenDioxide = try c.decodeIfPresent(Double.self, forKey: .nitrogenDioxide) ?? 0
        sulphurDioxide = try c.decodeIfPresent(Double.self, forKey: .sulphurDioxide) ?? 0
        ozone = try c.decodeIfPresent(Double.self, forKey: .ozone) ?? 0
    }

    /// Domain model used by the UI.
    func asCurrentAirQuality() -> CurrentAirQuality {
        CurrentAirQuality(
            usAQI: usAQI,
            pm10: pm10,
            pm2_5: pm2_5,
            carbonMonoxide: carbonMonoxide,
            nitrogenDioxide: nitrogenDioxide,
            sulphurDioxide: sulphurDioxide,
            ozone: ozone
        )
    }
}

struct HourlyUSAQIPayload: Codable {
    let time: [String]
    let usAqi: [Double?]

    enum CodingKeys: String, CodingKey {
        case time
        case usAqi = "us_aqi"
    }
}

/// Snapshot shown in the UI (decoded from API `current`).
struct CurrentAirQuality: Codable, Equatable {
    let usAQI: Int
    let pm10: Double
    let pm2_5: Double
    let carbonMonoxide: Double
    let nitrogenDioxide: Double
    let sulphurDioxide: Double
    let ozone: Double
}

/// Point for Swift Charts (last 24h trend).
struct AQIDataPoint: Identifiable, Equatable {
    let date: Date
    let usAQI: Int

    var id: Date { date }
}
