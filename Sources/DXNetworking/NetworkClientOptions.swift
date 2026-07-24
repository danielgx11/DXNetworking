import Foundation

public struct NetworkClientOptions {
    public var memoryCapacity: Int
    public var diskCapacity: Int
    public var requestCachePolicy: URLRequest.CachePolicy
    public var waitsForConnectivity: Bool
    public var timeoutIntervalForRequest: TimeInterval

    public init(
        memoryCapacity: Int = 1024 * 50,
        diskCapacity: Int = 1024 * 200,
        requestCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        waitsForConnectivity: Bool = true,
        timeoutIntervalForRequest: TimeInterval = 15
    ) {
        self.memoryCapacity = memoryCapacity
        self.diskCapacity = diskCapacity
        self.requestCachePolicy = requestCachePolicy
        self.waitsForConnectivity = waitsForConnectivity
        self.timeoutIntervalForRequest = timeoutIntervalForRequest
    }
}
