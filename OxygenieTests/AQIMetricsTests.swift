import XCTest
@testable import Oxygenie

final class AQIMetricsTests: XCTestCase {
    func testCategoryGood() {
        XCTAssertEqual(AQICategory.category(forUSAQI: 0), .good)
        XCTAssertEqual(AQICategory.category(forUSAQI: 50), .good)
    }

    func testCategoryModerate() {
        XCTAssertEqual(AQICategory.category(forUSAQI: 51), .moderate)
        XCTAssertEqual(AQICategory.category(forUSAQI: 100), .moderate)
    }

    func testCategoryHazardous() {
        XCTAssertEqual(AQICategory.category(forUSAQI: 301), .hazardous)
        XCTAssertEqual(AQICategory.category(forUSAQI: 500), .hazardous)
    }

    func testHealthRecommendationNonEmpty() {
        for c in AQICategory.allCases {
            XCTAssertFalse(c.healthRecommendation.isEmpty)
            XCTAssertFalse(c.displayName.isEmpty)
        }
    }
}
