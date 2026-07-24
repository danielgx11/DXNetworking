import Foundation

public enum CachePolicy: String, Sendable {
    case `public`
    case `private`
    case customController = "custom-controlled"
}

/// Protocol for intercepting URL cache operations.
public protocol CacheInterceptorProtocol: AnyObject, Sendable {

    var policy: CachePolicy { get }
    /// Intercepts cache responses before they are cached for a specific data task.
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse) async -> CachedURLResponse?
}

public final class DefaultCacheInterceptor: NSObject, URLSessionDataDelegate, CacheInterceptorProtocol {

    public let policy: CachePolicy

    public init(policy: CachePolicy = .public) {
        self.policy = policy
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse) async -> CachedURLResponse? {
        guard let httpResponse = proposedResponse.response as? HTTPURLResponse else {
            return proposedResponse
        }

        guard httpResponse.statusCode == 200,
              let cacheControl = httpResponse.value(forHTTPHeaderField: "Cache-Control"),
              cacheControl.contains(policy.rawValue)
        else {
            NetworkLogger.shared.log(type: .info, message: "Response was not cached. Status code: \(httpResponse.statusCode)")
            return nil
        }

        return proposedResponse
    }

    public func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        NetworkLogger.shared.log(type: .debug, message: "User has no connection established")
    }
}
