import Foundation

public final class SessionDelegate: NSObject {
    public weak var cacheInterceptor: CacheInterceptorProtocol? = nil
    public weak var metricsInterceptor: MetricsInterceptorProtocol? = nil
    public weak var taskLifecycleInterceptor: TaskLifecycleInterceptorProtocol? = nil

    override public init() {}
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
