import Foundation

struct NetworkClientOptions {
    var memoryCapacity: Int
    var diskCapacity: Int
    var requestCachePolicy: URLRequest.CachePolicy
    var waitsForConnectivity: Bool
    var timeoutIntervalForRequest: TimeInterval

    init(
        memoryCapacity: Int = 1024 * 50,
        diskCapacity: Int = 1024 * 200,
        requestCachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad,
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
