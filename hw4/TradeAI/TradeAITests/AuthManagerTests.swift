import XCTest
@testable import TradeAI

final class AuthManagerTests: XCTestCase {

    var sut: AuthManager!
    var keychain: MockKeychainService!

    override func setUp() {
        super.setUp()
        keychain = MockKeychainService()
        sut = AuthManager(keychain: keychain)
    }

    override func tearDown() {
        sut = nil
        keychain = nil
        super.tearDown()
    }

    func testSaveAndRetrieveToken() async throws {
        let tokens = AuthTokens(
            accessToken: "access123",
            refreshToken: "refresh456",
            expiresAt: Date().addingTimeInterval(3600)
        )

        await sut.saveTokens(tokens)
        let token = try await sut.validAccessToken()

        XCTAssertEqual(token, "access123")
        XCTAssertTrue(await sut.isAuthenticated())
    }

    func testLogoutClearsTokens() async {
        let tokens = AuthTokens(
            accessToken: "access123",
            refreshToken: "refresh456",
            expiresAt: Date().addingTimeInterval(3600)
        )

        await sut.saveTokens(tokens)
        await sut.logout()

        XCTAssertFalse(await sut.isAuthenticated())
    }
}

actor MockKeychainService: KeychainServiceProtocol {
    private var storage: [String: Data] = [:]

    func save(data: Data, key: String) async {
        storage[key] = data
    }

    func read(key: String) async -> Data? {
        return storage[key]
    }

    func delete(key: String) async {
        storage.removeValue(forKey: key)
    }
}
