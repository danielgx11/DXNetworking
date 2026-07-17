import Foundation
@testable import DXNetworking

struct StubEndpoint: Endpoint {
    var baseUrl: String
    var path: String
    var headers: [String: String]? = nil
    var method: HTTPMethod = .GET
    var body: Data? = nil
    var queryParameters: [URLQueryItem]? = nil
    var retries: Int = 0
}
