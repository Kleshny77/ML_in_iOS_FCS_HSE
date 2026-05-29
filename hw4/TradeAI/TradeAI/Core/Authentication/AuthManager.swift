import Foundation
import Combine

struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
}

enum AuthError: Error {
    case noRefreshToken
    case tokenRefreshFailed
    case notAuthenticated
}

actor AuthManager: AuthManagerProtocol, ObservableObject {

    @MainActor @Published private(set) var isLoggedIn: Bool = false

    private var apiKey: String?
    private let keychain: KeychainServiceProtocol

    init(
        keychain: KeychainServiceProtocol,
        apiKey: String? = nil
    ) {
        self.keychain = keychain
        self.apiKey = apiKey
    }

    func validAccessToken() async throws -> String {
        guard let key = apiKey else {
            throw AuthError.notAuthenticated
        }
        return key
    }

    func isAuthenticated() async -> Bool {
        let authenticated = apiKey != nil
        await MainActor.run { isLoggedIn = authenticated }
        return authenticated
    }

    func logout() async {
        apiKey = nil
        await keychain.delete(key: "api_key")
        await MainActor.run { isLoggedIn = false }
    }

    func saveAPIKey(_ key: String) async {
        self.apiKey = key
        if let data = key.data(using: .utf8) {
            await keychain.save(data: data, key: "api_key")
        }
        await MainActor.run { isLoggedIn = true }
    }

    private func loadAPIKeyFromKeychain() async -> String? {
        guard let data = await keychain.read(key: "api_key"),
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        self.apiKey = key
        return key
    }
}
