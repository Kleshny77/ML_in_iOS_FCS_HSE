import Foundation

protocol AuthManagerProtocol: AnyObject, Sendable {
    func validAccessToken() async throws -> String
    func isAuthenticated() async -> Bool
    func logout() async
}
