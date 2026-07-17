import Testing
import Foundation

@testable import DXNetworking

struct NetworkClientTests {

    @Test
    func sendDecodesResponseAndBuildsRequest() async throws {
        let payload = #"{"id":1,"name":"Daniel"}"#.data(using: .utf8)!
        let mockSession = MockURLSession { request in
            let response = Self.httpResponse(url: request.url!, statusCode: 200)
            return (payload, response)
        }
        let sut = NetworkClient(session: mockSession)

        let endpoint = StubEndpoint(
            baseUrl: "https://example.com",
            path: "/users",
            headers: ["Authorization": "Bearer token"],
            method: .GET,
            body: nil,
            queryParameters: [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "size", value: "20")
            ],
            retries: 0
        )

        let result: UserDTO = try await sut.send(endpoint)

        #expect(result == UserDTO(id: 1, name: "Daniel"))
        #expect(mockSession.callCount == 1)
        #expect(mockSession.lastRequest?.httpMethod == HTTPMethod.GET.stringValue)
        #expect(mockSession.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer token")
        #expect(mockSession.lastRequest?.url?.absoluteString == "https://example.com/users?page=1&size=20")
    }

    @Test
    func sendThrowsServerErrorForNon2xx() async {
        let mockSession = MockURLSession { request in
            let response = Self.httpResponse(url: request.url!, statusCode: 404)
            return (Data("{}".utf8), response)
        }
        let sut = NetworkClient(session: mockSession)
        let endpoint = StubEndpoint(baseUrl: "https://example.com", path: "/users", retries: 0)

        do {
            let _: UserDTO = try await sut.send(endpoint)
            Issue.record("Expected NetworkError.serverError(statusCode: 404)")
        } catch let error as NetworkError {
            #expect(error == .serverError(statusCode: 404))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func sendThrowsDecodingErrorAndDoesNotRetry() async {
        let invalidPayload = Data("{\"invalid\": true}".utf8)
        let mockSession = MockURLSession { request in
            let response = Self.httpResponse(url: request.url!, statusCode: 200)
            return (invalidPayload, response)
        }
        let sut = NetworkClient(session: mockSession)
        let endpoint = StubEndpoint(baseUrl: "https://example.com", path: "/users", retries: 3)

        do {
            let _: UserDTO = try await sut.send(endpoint)
            Issue.record("Expected NetworkError.decodingError")
        } catch let error as NetworkError {
            if case .decodingError = error {
                #expect(true)
            } else {
                Issue.record("Expected decodingError, got \(error)")
            }
            #expect(mockSession.callCount == 1)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func sendRetriesAndThrowsAfterExhaustion() async {
        let mockSession = MockURLSession { _ in
            throw URLError(.cannotFindHost)
        }
        let sut = NetworkClient(session: mockSession)
        let endpoint = StubEndpoint(baseUrl: "https://example.com", path: "/users", retries: 2)

        do {
            let _: UserDTO = try await sut.send(endpoint)
            Issue.record("Expected NetworkError.unknown")
        } catch let error as NetworkError {
            if case .unknown = error {
                #expect(true)
            } else {
                Issue.record("Expected unknown error, got \(error)")
            }
            #expect(mockSession.callCount == 3)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func sendMapsCancelledURLError() async {
        let mockSession = MockURLSession { _ in
            throw URLError(.cancelled)
        }
        let sut = NetworkClient(session: mockSession)
        let endpoint = StubEndpoint(baseUrl: "https://example.com", path: "/users", retries: 0)

        do {
            let _: UserDTO = try await sut.send(endpoint)
            Issue.record("Expected NetworkError.cancelled")
        } catch let error as NetworkError {
            #expect(error == .cancelled)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func sendMapsNoConnectionURLError() async {
        let mockSession = MockURLSession { _ in
            throw URLError(.notConnectedToInternet)
        }
        let sut = NetworkClient(session: mockSession)
        let endpoint = StubEndpoint(baseUrl: "https://example.com", path: "/users", retries: 0)

        do {
            let _: UserDTO = try await sut.send(endpoint)
            Issue.record("Expected NetworkError.noConnection")
        } catch let error as NetworkError {
            #expect(error == .noConnection)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    private static func httpResponse(url: URL, statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}





