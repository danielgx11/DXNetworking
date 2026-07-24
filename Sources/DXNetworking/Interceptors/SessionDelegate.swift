import Foundation

public final class SessionDelegate: NSObject {
    public let cacheInterceptor: CacheInterceptorProtocol?
    public let metricsInterceptor: MetricsInterceptorProtocol?
    public let taskLifecycleInterceptor: TaskLifecycleInterceptorProtocol?

    public init(
        cacheInterceptor: CacheInterceptorProtocol? = nil,
        metricsInterceptor: MetricsInterceptorProtocol? = nil,
        taskLifecycleInterceptor: TaskLifecycleInterceptorProtocol? = nil
    ) {
        self.cacheInterceptor = cacheInterceptor
        self.metricsInterceptor = metricsInterceptor
        self.taskLifecycleInterceptor = taskLifecycleInterceptor
    }
}

// MARK: - URLSessionDelegate

extension SessionDelegate: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        taskLifecycleInterceptor?.urlSession(session, didCreateTask: task)
    }
}

// MARK: - URLSessionDataDelegate

extension SessionDelegate: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse) async -> CachedURLResponse? {
        await cacheInterceptor?.urlSession(session, dataTask: dataTask, willCacheResponse: proposedResponse) ?? proposedResponse
    }
}

// MARK: - URLSessionTaskDelegate

extension SessionDelegate: URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        metricsInterceptor?.urlSession(session, task: task, didFinishCollecting: metrics)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        taskLifecycleInterceptor?.urlSession(session, task: task, didCompleteWithError: error)
    }

    public func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        taskLifecycleInterceptor?.urlSession(session, taskIsWaitingForConnectivity: task)
    }
}
