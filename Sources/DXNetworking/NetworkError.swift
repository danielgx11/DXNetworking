import Foundation

public enum NetworkError: LocalizedError, Equatable {
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidBaseUrl, .invalidBaseUrl),
             (.invalidResponse, .invalidResponse),
             (.noData, .noData),
             (.timeout, .timeout),
             (.noConnection, .noConnection),
             (.cancelled, .cancelled):
            return true
        case (.serverError(let l), .serverError(let r)):
            return l == r
        case (.decodingError(let l), .decodingError(let r)):
            return l.localizedDescription == r.localizedDescription
        case (.unknown(let l), .unknown(let r)):
            return l.localizedDescription == r.localizedDescription
        default:
            return false
        }
    }

    case invalidBaseUrl
    case invalidResponse
    case noData
    case timeout
    case noConnection
    case cancelled
    case serverError(statusCode: Int)
    case decodingError(Error)
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidBaseUrl:
            return "Invalid base URL"
        case .invalidResponse:
            return "Response is not valid"
        case .noData:
            return "Data is empty"
        case .serverError(let statusCode):
            return "Server Error \(statusCode)"
        case .decodingError(let error):
            return "Decoding Error \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown Error \(error.localizedDescription)"
        case .cancelled:
            return "The operation was cancelled"
        case .noConnection:
            return "No connection detected"
        case .timeout:
            return "Timeout reached"
        }
    }
}
