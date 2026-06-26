import os
import Foundation

final class NetworkLogger: Sendable {

    static let shared = NetworkLogger()

    // TODO: - Phase 5 #23 — Call from NetworkClient to log: request URL+method pre-send, status code+latency on response, error detail on failure
    func log(type: NetworkLoggerType = .default, message: String) {
        let general = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "com.networking.extension",
            category: "Networking"
        )

        general.log(level: type.asLoggerType, "\(message)")
    }
}

enum NetworkLoggerType {
    case `default`
    case info
    case debug
    case error

    var asLoggerType: OSLogType {
        switch self {
        case .default:
            return .default
        case .info:
            return .info
        case .debug:
            return .debug
        case .error:
            return .error
        }
    }
}
