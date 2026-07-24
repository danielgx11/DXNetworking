import Foundation

/// Protocol for intercepting URL metrics collection.
public protocol MetricsInterceptorProtocol: AnyObject, Sendable {
    /// Intercepts metrics after task completion.
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics)
}

public final class DefaultMetricsInterceptor: MetricsInterceptorProtocol {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        // TODO: work here
        NetworkLogger.shared
            .log(
                type: .debug,
                message: "Retry count -> \(metrics.redirectCount)"
            )
    }
    

}
