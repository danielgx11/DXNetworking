import Foundation

protocol Endpoint {
    // The path for the endpoint. This is the part of the URL after the host of the API
    var baseUrl: String { get }
    // The path for the endpoint. This is the part of the URL after the host of the API
    var path: String { get }
    // Headers to be sent in the request
    var headers: [String: String]? { get }
    // The HTTP method for this endpoint
    var method: HTTPMethod { get }
    // Parameters sent in the request body. It can't be used in `GET` requests
    var body: Data? { get }
    // Parameters sent in the URL.
    var queryParameters: [URLQueryItem]? { get }
    // Retry quantity
    var retries: Int { get }
    // TODO: - Phase 3 — Consider adding a per-endpoint timeoutInterval: TimeInterval property so individual targets can override the session default
    // TODO: - Phase 3 #17 — Add a protocol extension with default implementations (nil headers/params, retries = 2) to avoid boilerplate in every target
}
