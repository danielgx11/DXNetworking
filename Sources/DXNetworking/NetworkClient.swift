import Foundation

public protocol NetworkClientProtocol {
    func send<T: Decodable>(
        _ endpoint: Endpoint
    ) async throws -> T

    func send(
        _ endpoint: Endpoint
    ) async throws
}

// TODO: - Phase 6 #28 — Evaluate Sendable conformance or convert to actor for safe concurrent access across async contexts
public final class NetworkClient: NetworkClientProtocol {

    private let session: URLSessionProtocol
    private let decoder: JSONDecoder

    public init(
        session: URLSessionProtocol,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.decoder = decoder
    }

    public convenience init(
        options: NetworkClientOptions = NetworkClientOptions(),
        sessionDelegate: SessionDelegate? = nil,
        delegateQueue: OperationQueue? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        let cache = URLCache(
            memoryCapacity: options.memoryCapacity,
            diskCapacity: options.diskCapacity
        )
        let configuration: URLSessionConfiguration = .default
        configuration.requestCachePolicy = options.requestCachePolicy
        configuration.urlCache = cache
        configuration.waitsForConnectivity = options.waitsForConnectivity
        configuration.timeoutIntervalForRequest = options.timeoutIntervalForRequest

        let cacheInterceptor = DefaultCacheInterceptor()
        let metricsInterceptor = DefaultMetricsInterceptor()
        let taskLifecycleInterceptor = DefaultTaskLifecycleInterceptor()
        let resolvedDelegate = sessionDelegate ?? SessionDelegate(
            cacheInterceptor: cacheInterceptor,
            metricsInterceptor: metricsInterceptor,
            taskLifecycleInterceptor: taskLifecycleInterceptor
        )

        let urlSession = URLSession(
            configuration: configuration,
            delegate: resolvedDelegate,
            delegateQueue: delegateQueue
        )

        self.init(session: urlSession, decoder: decoder)
    }

    public func send<T: Decodable>(
        _ endpoint: Endpoint
    ) async throws -> T {
        try await withRetries(endpoint) {
            try await self.fetch(from: endpoint)
        }
    }

    public func send(
        _ endpoint: Endpoint
    ) async throws {
        try await withRetries(endpoint) {
            _ = try await self.performRequest(endpoint)
        }
    }

    // TODO: - Phase 5 #20 — Replace fixed base delay with configurable backoff strategy (currently exponential + jitter, single source of truth here)
    private func withRetries<T>(
        _ endpoint: Endpoint,
        operation: () async throws -> T
    ) async throws -> T {
        let sleepTimeMultiplier: Double = 1_000_000_000
        let base = 0.25
        let maxInterval = 60.0
        var lastError: Error?
        let retryCount = max(0, endpoint.retries)

        for attempt in 0...retryCount {
            do {
                return try await operation()
            } catch let error as NetworkError {
                switch error {
                case .invalidResponse, .noData, .invalidBaseUrl, .decodingError, .cancelled:
                    throw error
                default:
                    lastError = error
                }
            } catch {
                lastError = error
            }

            guard attempt < retryCount else {
                break
            }

            let sleep = base * Double(pow(Double(2), Double(attempt)))
            let seconds = Double.random(in: 0...min(maxInterval, sleep))
            try await Task.sleep(nanoseconds: UInt64(seconds * sleepTimeMultiplier))
        }

        throw lastError ?? NetworkError.unknown(NSError(domain: "", code: -999))
    }

    private func fetch<T>(
        from endpoint: any Endpoint
    ) async throws -> T where T : Decodable {
        let (data, _) = try await performRequest(endpoint)

        guard !data.isEmpty else {
            throw NetworkError.noData
        }

        return try decode(from: data)
    }

    @discardableResult
    private func performRequest(_ endpoint: Endpoint) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: endpoint.baseUrl) else {
            throw NetworkError.invalidBaseUrl
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.path += endpoint.path
        components?.queryItems = endpoint.queryParameters

        // TODO: verify when delegate is needed
        ////        let session = URLSession(configuration: URLSessionConfiguration, delegate: (any URLSessionDelegate)?, delegateQueue: OperationQueue?)

        var urlRequest = URLRequest(
            url: components?.url ?? url
        )

        urlRequest.httpMethod = endpoint.method.stringValue
        urlRequest.httpBody = endpoint.body
        endpoint.headers?.forEach {
            urlRequest.setValue($1, forHTTPHeaderField: $0)
        }
        if endpoint.body != nil, urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        // TODO: - Phase 5 #23 — Log request URL + method via NetworkLogger.shared.log before send

        do {
            let (data, response) = try await session.data(for: urlRequest, delegate: nil) // Delegate here? for what would we need it?

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard 200..<300 ~= httpResponse.statusCode else {
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }

            return (data, httpResponse)
        } catch let networkError as NetworkError {
            throw networkError
        } catch let urlError as URLError {
            switch urlError.code {
            case .timedOut:
                throw NetworkError.timeout
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .dataNotAllowed:
                throw NetworkError.noConnection
            case .cancelled:
                throw NetworkError.cancelled
            case .cannotDecodeRawData, .cannotDecodeContentData:
                throw NetworkError.decodingError(urlError)
            default:
                throw NetworkError.unknown(urlError)
            }
        } catch {
            NetworkLogger.shared.log(message: error.localizedDescription)
            throw NetworkError.unknown(error)
        }
    }

    private func decode<T: Decodable>(from data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}

extension NetworkClient: RequestInterceptor {
    public func adapt(request: URLRequest) throws -> URLRequest {
        debugPrint(#function)

        return request
    }
    
    public func retry(request: URLRequest, dueTo error: any Error, attemptCount: Int) async -> RetryResult {
        debugPrint(#function)
//        let sleep = base * Double(pow(Double(2), Double(attempt)))
//        let seconds = Double.random(in: 0...min(maxInterval, sleep))
//        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        return .retry
    }
    

}
