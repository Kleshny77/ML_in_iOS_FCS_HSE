import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case notFound
    case serverError(statusCode: Int)
    case decodingFailed(underlying: Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .unauthorized: return "Unauthorized - please check your API key"
        case .notFound: return "Resource not found"
        case .serverError(let code): return "Server error: \(code)"
        case .decodingFailed(let error): return "Failed to decode response: \(error.localizedDescription)"
        case .noData: return "No data received"
        }
    }
}

protocol Endpoint: Sendable {
    var path: String { get }
    var method: String { get }
    var headers: [String: String]? { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
}

extension Endpoint {
    var method: String { "GET" }
    var headers: [String: String]? { nil }
    var queryItems: [URLQueryItem]? { nil }
    var body: Data? { nil }
}

protocol APIClientProtocol: Sendable {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func request(_ endpoint: Endpoint) async throws -> Data
}

final class APIClient: APIClientProtocol, @unchecked Sendable {

    private let baseURL: URL
    private let urlSession: URLSession
    private let authManager: AuthManagerProtocol

    init(
        baseURL: URL,
        authManager: AuthManagerProtocol,
        urlSession: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.authManager = authManager
        self.urlSession = urlSession
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await request(endpoint)
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch {
            let preview = String(data: data, encoding: .utf8)?.prefix(200) ?? "<binary>"
            print("[APIClient] DECODE ERROR for \(endpoint.path): \(error)")
            print("[APIClient] Response preview: \(preview)")
            throw NetworkError.decodingFailed(underlying: error)
        }
    }

    func request(_ endpoint: Endpoint) async throws -> Data {
        let authToken = try await authManager.validAccessToken()
        let request = try buildRequest(for: endpoint, authToken: authToken)
        print("[APIClient] REQUEST: \(request.url?.absoluteString ?? "nil")")
        let (data, response) = try await urlSession.data(for: request)
        if let http = response as? HTTPURLResponse {
            print("[APIClient] RESPONSE status: \(http.statusCode)")
        }
        try validate(response: response)
        print("[APIClient] Response preview: \(String(data: data, encoding: .utf8)?.prefix(200) ?? "<binary>")")
        return data
    }

    private func buildRequest(for endpoint: Endpoint, authToken: String) throws -> URLRequest {
        let url = baseURL.appendingPathComponent(endpoint.path)
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw NetworkError.invalidURL
        }

        var queryItems = endpoint.queryItems ?? []
        queryItems.append(URLQueryItem(name: "access_key", value: authToken))
        components.queryItems = queryItems

        guard let finalURL = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = endpoint.method
        request.httpBody = endpoint.body
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = endpoint.body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        }

        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw NetworkError.unauthorized
        case 404:
            throw NetworkError.notFound
        default:
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
    }
}
