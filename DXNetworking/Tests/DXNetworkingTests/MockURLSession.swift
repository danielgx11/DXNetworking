import Foundation
@testable import DXNetworking

final class MockURLSession: URLSessionProtocol {
    private let handler: (URLRequest) async throws -> (Data, URLResponse)

    private(set) var callCount = 0
    private(set) var lastRequest: URLRequest?

    init(handler: @escaping (URLRequest) async throws -> (Data, URLResponse)) {
        self.handler = handler
    }

    func data(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (Data, URLResponse) {
        callCount += 1
        lastRequest = request
        return try await handler(request)
    }
}
