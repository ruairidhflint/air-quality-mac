import Foundation

/// US EPA AQI category and user-facing copy (logic only; no SwiftUI — easy to unit test).
enum AQICategory: String, CaseIterable, Sendable {
    case good
    case moderate
    case unhealthySensitive
    case unhealthy
    case veryUnhealthy
    case hazardous

    var displayName: String {
        switch self {
        case .good: return "Good"
        case .moderate: return "Moderate"
        case .unhealthySensitive: return "Unhealthy for Sensitive Groups"
        case .unhealthy: return "Unhealthy"
        case .veryUnhealthy: return "Very Unhealthy"
        case .hazardous: return "Hazardous"
        }
    }

    /// Short guidance shown in the popover.
    var healthRecommendation: String {
        switch self {
        case .good:
            return "Air quality is satisfactory. Normal outdoor activity is fine."
        case .moderate:
            return "Acceptable for most people. Very sensitive individuals may want to limit prolonged outdoor exertion."
        case .unhealthySensitive:
            return "Children, older adults, and people with heart or lung disease should reduce prolonged outdoor exertion."
        case .unhealthy:
            return "Everyone may begin to feel effects; sensitive groups should avoid prolonged outdoor exertion. Consider reducing time outdoors."
        case .veryUnhealthy:
            return "Health alert: everyone may experience serious effects. Avoid outdoor activities."
        case .hazardous:
            return "Emergency conditions. Everyone should avoid all outdoor exertion and stay indoors if possible."
        }
    }

    static func category(forUSAQI aqi: Int) -> AQICategory {
        switch aqi {
        case ...50: return .good
        case 51...100: return .moderate
        case 101...150: return .unhealthySensitive
        case 151...200: return .unhealthy
        case 201...300: return .veryUnhealthy
        default: return .hazardous
        }
    }
}
