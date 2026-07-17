import Foundation

/// Protocol for intercepting URL metrics collection.
public protocol MetricsInterceptorProtocol: AnyObject {
    /// Intercepts metrics after task completion.
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics)
}

final class MetricsInterceptor: MetricsInterceptorProtocol {
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        // TODO: work here
        NetworkLogger.shared
            .log(
                type: .debug,
                message: "Retry count -> \(metrics.redirectCount)"
            )
    }
    

}
