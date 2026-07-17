import Foundation

protocol RequestInterceptor {
    func adapt(request: URLRequest) throws -> URLRequest
    func retry(request: URLRequest, dueTo error: Error, attemptCount: Int) async -> RetryResult
}
