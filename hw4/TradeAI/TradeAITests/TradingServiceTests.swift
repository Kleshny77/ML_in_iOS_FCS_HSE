import XCTest
@testable import TradeAI

final class TradingServiceTests: XCTestCase {

    var sut: TradingService!
    var mockAPIClient: MockAPIClient!

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        sut = TradingService(apiClient: mockAPIClient)
    }

    override func tearDown() {
        sut = nil
        mockAPIClient = nil
        super.tearDown()
    }

    func testFetchAccounts() async throws {
        let json = """
        {
            "accounts": [
                {
                    "id": "1",
                    "balance": 10000.0,
                    "NAV": 10050.0,
                    "marginUsed": 100.0,
                    "marginAvailable": 9900.0,
                    "openTradeCount": 1,
                    "openPositionCount": 1,
                    "pendingOrderCount": 0,
                    "pl": 50.0,
                    "currency": "USD"
                }
            ]
        }
        """.data(using: .utf8)!

        mockAPIClient.nextResponse = json
        let accounts = try await sut.fetchAccounts()

        XCTAssertEqual(accounts.count, 1)
        XCTAssertEqual(accounts.first?.balance, 10000.0)
    }
}

actor MockAPIClient: APIClientProtocol {
    var nextResponse: Data = Data()
    var nextError: Error?

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        if let error = nextError { throw error }
        return try JSONDecoder().decode(T.self, from: nextResponse)
    }

    func request(_ endpoint: Endpoint) async throws -> Data {
        if let error = nextError { throw error }
        return nextResponse
    }
}
