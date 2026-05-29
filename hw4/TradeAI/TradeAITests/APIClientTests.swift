import XCTest
@testable import TradeAI

final class APIClientTests: XCTestCase {

    var sut: APIClient!
    var mockAuthManager: MockAuthManager!
    var mockURLSession: URLSession!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockURLSession = URLSession(configuration: config)
        mockAuthManager = MockAuthManager()
        sut = APIClient(baseURL: URL(string: "https://api.test.com")!, authManager: mockAuthManager, urlSession: mockURLSession)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        sut = nil
        mockAuthManager = nil
        mockURLSession = nil
        super.tearDown()
    }

    func testRequest_Success() async throws {
        let expectedData = "{\"accounts\": [{\"id\":\"1\"}]}".data(using: .utf8)!
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, expectedData)
        }

        struct TestEndpoint: Endpoint {
            var path: String { "/test" }
        }

        struct Response: Decodable {
            let accounts: [AccountStub]
        }
        struct AccountStub: Decodable {
            let id: String
        }

        let result: Response = try await sut.request(TestEndpoint())
        XCTAssertEqual(result.accounts.first?.id, "1")
    }

    func testRequest_Unauthorized() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        struct TestEndpoint: Endpoint {
            var path: String { "/test" }
        }

        do {
            let _: Data = try await sut.request(TestEndpoint())
            XCTFail("Expected unauthorized error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.unauthorized)
        } catch {
            XCTFail("Unexpected error type")
        }
    }
}

actor MockAuthManager: AuthManagerProtocol {
    func validAccessToken() async throws -> String {
        "mock_token"
    }

    func isAuthenticated() async -> Bool {
        true
    }

    func logout() async {}
}

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler is unavailable.")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
