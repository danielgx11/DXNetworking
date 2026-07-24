import Foundation

/// Protocol for intercepting task lifecycle events.
public protocol TaskLifecycleInterceptorProtocol: AnyObject, Sendable {
    /// Intercepts when a task completes with or without an error.
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)

    /// Intercepts when a task is waiting for connectivity.
    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask)

    /// Intercepts when a task is created.
    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask)
}

public final class DefaultTaskLifecycleInterceptor: TaskLifecycleInterceptorProtocol {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        NetworkLogger.shared.log(message: "Task finished with error \(String(describing: error?.localizedDescription))")
    }
    
    public func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        NetworkLogger.shared.log(message: "Task is waiting for connectivity")
    }
    
    public func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        NetworkLogger.shared.log(message: "Task was created")

    }

}
