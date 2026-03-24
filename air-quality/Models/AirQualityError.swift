import Foundation

enum AirQualityError: LocalizedError {
    case invalidURL
    case noData
    case httpStatus(Int)
    case decoding(Error)
    case network(URLError)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL."
        case .noData:
            return "No data was returned by the server."
        case .httpStatus(let code):
            return "Server returned status code \(code)."
        case .decoding(let error):
            return "Could not read air quality data: \(error.localizedDescription)"
        case .network(let error):
            return error.localizedDescription
        }
    }
}
