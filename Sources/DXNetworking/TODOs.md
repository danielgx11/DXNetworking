# TODOs — Networking Package

A phased roadmap to evolve this lib into a production-ready, interview-ready package.  
Tackle phases in order — each builds on the previous.

---

## Phase 1 — Fix Existing Gaps (ship-blockers)

These are bugs or incomplete wiring already in the codebase. None require new files.

1. **Wire `headers` from `Endpoint` into `URLRequest`**  
   Both `fetchVoid` and `fetch` build the request but never apply `endpoint.headers`. Any auth token or API key set on a target is silently dropped.  
   → See `// TODO:` markers in `NetworkClient.swift`. ✅

2. **Wire `queryParameters` into the URL**  
   `queryParameters` on `Endpoint` is defined but never consumed. Use `URLComponents` to append query items before building the request.  
   → Search: "URLComponents queryItems Swift" on Apple Developer docs. ✅

3. **Fix status code range off-by-one**  
   `200..<299` excludes 299. Change to `200..<300`. ✅

4. **Replace `[String: Any]` body with `Encodable`**  
   `bodyParameters: [String: Any]?` loses type safety and requires `JSONSerialization`. Switching to `Encodable` lets you use `JSONEncoder` and removes stringly-typed dictionaries.  
   → Search: "URLRequest Encodable body Swift" on Apple Developer docs. ✅
   
   Follow ups: What if I use Data directly on Endpoint.swift?

5. **Deduplicate `fetch` and `fetchVoid`**  
   Both share URL building, header wiring, and response validation. Extract a single `performRequest(_ endpoint:) async throws -> (Data, HTTPURLResponse)` and have each call it. ✅

6. **Deduplicate retry logic**  
   Both `send` overloads copy the same retry loop. Extract a generic `withRetry<T>(retries:operation:) async throws -> T` wrapper. See Phase 3 for the interceptor-based upgrade. ✅
   
   Follow up: I havent checked the Phase 3 yet.

7. **Remove `HTTPMethod.stringValue`**  
   It just wraps `rawValue`. Callers should use `.rawValue` directly. ✅ 
   
   Follow up: I preffer like that

8. **Fix `NetworkError.Equatable`**  
   Comparing `localizedDescription` strings is fragile — different OS versions can produce different strings. Implement `==` case-by-case.  
   → Search: "Swift enum Equatable associated values" on StackOverflow or Swift Forums.

    Follow up: Please help me on this cuz some cases does not have associated values or if have they have Error associated which makes only comparable the localizedDescription

9. **Add missing `NetworkError` cases**  
   - `case timeout` — distinguish from generic `unknown`  
   - `case noConnection` — surface before a request fires (see Phase 5 #21)  
   - `case cancelled` — map from `URLError.cancelled` ✅

10. **Adopt `LocalizedError` on `NetworkError`**  
    Implement `errorDescription: String?` via `LocalizedError` so `error.localizedDescription` works natively. The separate `NetworkError+Description` extension can then be removed.  
    → Apple doc: `LocalizedError` protocol. ✅

---

## Phase 2 — Testability (I will do next)

Without this phase the lib cannot be unit-tested — a red flag in interviews.

11. **Abstract `URLSession` behind a protocol**  
    Introduce `URLSessionProtocol` with `data(for:delegate:) async throws -> (Data, URLResponse)`. Make `URLSession` conform via an extension and inject the protocol into `NetworkClient`.  
    → Search: "mock URLSession Swift async" — look at both the `URLProtocol` mock pattern and the protocol-wrapper approach. Both are valid interview topics.  
    → Apple doc: `URLProtocol` subclassing.

12. **Create test stubs**  
    `MockURLSession`, `StubEndpoint`, and factory helpers for canned `(Data, HTTPURLResponse)` responses. Keep these in the test target only.

13. **Write unit tests for `NetworkClient`**  
    Scenarios to cover:  
    - Successful decode  
    - Server error (4xx, 5xx)  
    - Decoding error  
    - Retry exhaustion (assert attempt count)  
    - Cancellation (Phase 5 #22 first)  
    - `noConnection` fast-fail  
    → Check the `swift-testing-expert` skill if you want `#expect` / `#require` instead of XCTest assertions.

---

## Phase 3 — Configuration & Architecture

14. **Extract session / cache configuration**  
    Move cache capacities, timeout, and `URLSessionConfiguration` out of `NetworkClient.init` into a `NetworkSessionBuilder` factory. `NetworkClient` should receive a fully built `URLSession`.  
    → The `// TODO: this implementation needs to be OUTSIDE this class (SoC)` comment in `NetworkClient.swift` already flags this.
    
    Follow up: We will do it when we have this networking as an external lib

15. **Introduce a request interceptor chain**  
    Define a `RequestInterceptor` protocol:  
    ```
    adapt(request: URLRequest) throws -> URLRequest
    retry(request: URLRequest, dueTo error: Error, attemptCount: Int) -> Bool
    ```  
    Auth token injection, cache overrides, logging, and retry strategy all become composable interceptors. `CacheInterceptor` evolves into one of these.  
    → Study: Moya's `PluginType`, Alamofire's `RequestInterceptor`  
    → WWDC 2018: "Optimizing Your App for Today's Internet" (URLSession delegate patterns). ✅

16. **Make `JSONDecoder` injectable**  
    Accept a `JSONDecoder` in `NetworkClient.init` (or expose on `Endpoint`) so callers can set `keyDecodingStrategy`, `dateDecodingStrategy`, or custom strategies per target. ✅

17. **Default implementations via protocol extension on `Endpoint`**  
    Provide sensible defaults: `headers = nil`, `bodyParameters = nil`, `queryParameters = nil`, `retries = 2`. This removes the boilerplate `switch` returning `nil` / defaults in every target like `UsersTarget`.
    
    Follow up: does it make sense? in this case its not good to force consumers to implement every time?

---

## Phase 4 — Security

18. **SSL Pinning**  
    Implement `urlSession(_:didReceive:completionHandler:)` on a `URLSessionDelegate` to validate the server certificate or public key against bundled trusted pins. This is an interceptor candidate from Phase 3 #15.  
    → Apple doc: "Performing Manual Server Trust Authentication"  
    → Search: "TrustKit iOS" for a battle-tested lib  
    → WWDC 2017: "Your Apps and Evolving Network Security Standards"

19. **ATS (App Transport Security)**  
    Configure `NSAppTransportSecurity` in `Info.plist`. Know the difference between `NSExceptionDomains` (scoped) and `NSAllowsArbitraryLoads` (blanket disable — a red flag in App Store review). For interviews: be able to explain *why* ATS exists, not just how to configure it.  
    → Apple doc: `NSAppTransportSecurity` key reference.

    Follow up:
    `NSAppTransportSecurity` -> Feature on your info.plist called ATS to increase security or create exceptions for your requests
    `NSExceptionDomains` -> List of domains out of the ATS security
    `NSAllowsArbitraryLoads` -> The NSAllowArbitraryLoads key is set to NO by default. Setting the key to YES will opt-out of ATS and its associated security benefits.
    
    Article: https://medium.com/@abhishek.dev.kumar.94/ios-app-transport-security-secure-connection-b8bd99b5ddc8
    
    For Your Interviews: The "Why" Behind ATS
Since your roadmap highlights knowing why ATS exists, keep these three core pillars in mind for an interview response:
**Enforcing Ecosystem-Wide Privacy:** 
Before ATS (introduced in iOS 9), developers frequently cut corners by using http:// to avoid the hassle or cost of setting up SSL certificates. Apple introduced ATS to force the entire iOS ecosystem toward mandatory encryption, protecting user data from eavesdropping.
**Preventing Man-in-the-Middle (MITM) Attacks:** 
ATS doesn't just mandate HTTPS; it mandates good HTTPS. It requires specific cipher suites and a minimum of TLS 1.2. This ensures a malicious actor cannot intercept and alter the data passing between your app and the backend.
**Forward Secrecy:**
 ATS requires Perfect Forward Secrecy (PFS). This means that even if a server's private key is somehow stolen or compromised in the future, an attacker still cannot decrypt past network traffic they might have recorded.

---

## Phase 5 — Resilience & Observability

20. **Exponential backoff with jitter**  
    Replace the fixed 1-second retry delay with `min(maxDelay, baseDelay * pow(2, attempt)) + randomJitter`.  
    → Search: "exponential backoff jitter" — the AWS Architecture Blog article explains the jitter rationale well and is language-agnostic.
    
    For interviews ready:
    Exponencial backoff and Jitter its good to help in cases where we have multiple users trying to connect to a service which can down the server. Multiple devices trying to connect at the same time can lead to delays and more and more problems. The solution is Exponencial backoff with jitter
    
    - At its core, **Exponential Backoff** is a retry algorithm where, after each failure, you wait twice as long as you did last time before trying again.
    Instead of retrying every second, you slow down giving the system a chance to breathe and recover.
    Exponential Backoff spaces out retries, so the system doesn’t get overwhelmed the moment it comes back.
    With a fixed delay if you have 1 million clients it will be 1 million retries at the same time

    - **jitter** Its a way to randomize it to make all available "slots" of retry filled at least by 1 client

21. **Network reachability via `NWPathMonitor`**  
    Wrap `NWPathMonitor` to surface connectivity state. Throw `noConnection` before firing a request when the path is unsatisfied.  
    → Apple doc: `NWPathMonitor`  
    → WWDC 2019: "Advances in Networking, Part 1"

22. **Request cancellation**  
    Expose `Task` handles from `send` or return a `NetworkTask` wrapper so callers can cancel in-flight work. Use `withTaskCancellationHandler` internally to cancel the underlying `URLSessionTask`.  
    → Apple doc: `withTaskCancellationHandler(operation:onCancel:)`

23. **Structured request / response logging**  
    `NetworkLogger` already uses `os.Logger` (good). Wire it into `NetworkClient` to log: request URL + method before send, status code + latency on response, and error detail on failure. This supersedes the original TODO #3.

---

## Phase 6 — Advanced / Interview Differentiators

24. **Background sessions**  
    `URLSessionConfiguration.background(withIdentifier:)` for upload/download tasks that survive app suspension. Requires handling `backgroundSessionCompletionHandler` in `AppDelegate` / `SceneDelegate`. This was the original TODO #1.  
    → Apple doc: "Downloading Files in the Background"

25. **Multipart / upload support**  
    Use `httpBodyStream` with `InputStream` for large payloads. Track progress via `URLSessionTaskDelegate.urlSession(_:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)`.

26. **Download with progress**  
    `URLSessionDownloadTask` + `URLSessionDownloadDelegate.urlSession(_:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)`.

27. **Package as Swift Package (SPM)**  
    Restructure the networking code as a Swift Package (`Package.swift`). Domain-level code (`UsersTarget`, `UserResponse`) stays in the consumer app. This is the end goal for cross-project reuse.  
    → Apple doc: "Creating a Swift Package" in the Swift Package Manager documentation.

28. **`Sendable` and actor isolation**  
    Mark `NetworkClient` as `Sendable` or convert to an `actor` for safe concurrent access. Audit all stored properties.  
    → WWDC 2021: "Swift concurrency: Behind the scenes"  
    → WWDC 2022: "Eliminate data races using Swift Concurrency"

29. **OperationQueue + URLSession task priorities**  
    Use `OperationQueue` as the `delegateQueue` to gain task prioritisation and dependency management. Pairs well with background sessions (Phase 6 #24). This was the original TODO #1 intent.

30. **Combine / AsyncSequence bridge (optional)**  
    Expose a `Publisher` or `AsyncStream` alternative for consumers who prefer reactive-style composition. Demonstrates API design awareness without replacing the async/await core.
