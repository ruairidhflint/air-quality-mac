import AppKit

extension NSColor {
    /// US EPA-style AQI tint for menu bar / AppKit.
    static func oxygenieAQI(forUSAQI aqi: Int) -> NSColor {
        switch aqi {
        case ...50:
            return .systemGreen
        case 51...100:
            return .systemYellow
        case 101...150:
            return .systemOrange
        case 151...200:
            return .systemRed
        case 201...300:
            return .systemPurple
        default:
            return NSColor(red: 0.5, green: 0, blue: 0, alpha: 1)
        }
    }
}
