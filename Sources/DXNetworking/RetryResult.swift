import Foundation

enum RetryResult: Sendable {
    /// Retry immediately
    case retry
    /// The interceptor calculated the backoff + jitter
    case retryWithDelay(TimeInterval)
    /// Hard stop
    case doNotRetry
}
