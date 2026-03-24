import Foundation
import os.log

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "Oxygenie"

    static let general = Logger(subsystem: subsystem, category: "general")
    static let location = Logger(subsystem: subsystem, category: "location")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let notifications = Logger(subsystem: subsystem, category: "notifications")
}
