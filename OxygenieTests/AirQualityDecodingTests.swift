import XCTest
@testable import Oxygenie

final class AirQualityDecodingTests: XCTestCase {
    func testDecodeOpenMeteoCurrentWithoutHourly() throws {
        let json = """
        {
          "current": {
            "time": "2024-06-01T12:00",
            "interval": 3600,
            "us_aqi": 42,
            "pm10": 10.5,
            "pm2_5": 5.25,
            "carbon_monoxide": 120,
            "nitrogen_dioxide": 8,
            "sulphur_dioxide": 2,
            "ozone": 45
          }
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(OpenMeteoAirQualityResponse.self, from: json)
        XCTAssertEqual(decoded.current.asCurrentAirQuality().usAQI, 42)
        XCTAssertNil(decoded.hourly)
    }

    func testDecodeUsAqiAsDouble() throws {
        let json = """
        {
          "current": {
            "us_aqi": 88.7,
            "pm10": 0,
            "pm2_5": 0,
            "carbon_monoxide": 0,
            "nitrogen_dioxide": 0,
            "sulphur_dioxide": 0,
            "ozone": 0
          }
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(OpenMeteoAirQualityResponse.self, from: json)
        XCTAssertEqual(decoded.current.asCurrentAirQuality().usAQI, 89)
    }
}
