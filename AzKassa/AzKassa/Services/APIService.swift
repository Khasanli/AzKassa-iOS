import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case notFound
    case serverError(String)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Giriş tələb olunur"
        case .notFound: return "Tapılmadı"
        case .serverError(let msg): return msg
        case .decodingError(let e): return "Məlumat xətası: \(e.localizedDescription)"
        }
    }
}

final class APIService {
    static let shared = APIService()
    private init() {}

    // Change to your server URL
    private let baseURL = "http://178.105.243.22/api"

    private var token: String? {
        UserDefaults.standard.string(forKey: "mkassa_token")
    }

    private func makeRequest(_ path: String, method: String = "GET", body: Encodable? = nil) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.serverError("Invalid URL")
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body { req.httpBody = try JSONEncoder().encode(body) }
        return req
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.serverError("No response") }
        switch http.statusCode {
        case 200...299:
            do { return try JSONDecoder().decode(T.self, from: data) }
            catch { throw APIError.decodingError(error) }
        case 401: throw APIError.unauthorized
        case 404: throw APIError.notFound
        default:
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? "Server error \(http.statusCode)"
            throw APIError.serverError(msg)
        }
    }

    // MARK: - Auth

    func login(email: String, password: String) async throws -> LoginResponse {
        struct Body: Encodable { let email: String; let password: String }
        var req = try makeRequest("/auth/login", method: "POST", body: Body(email: email, password: password))
        req.setValue(nil, forHTTPHeaderField: "Authorization")
        return try await perform(req)
    }

    func staffLogin(username: String, password: String, businessId: String) async throws -> LoginResponse {
        struct Body: Encodable { let username: String; let password: String; let businessId: String }
        var req = try makeRequest("/auth/staff/login", method: "POST", body: Body(username: username, password: password, businessId: businessId))
        req.setValue(nil, forHTTPHeaderField: "Authorization")
        return try await perform(req)
    }

    // MARK: - Products

    func fetchProducts(search: String? = nil, category: String? = nil) async throws -> [Product] {
        var path = "/products"
        var params: [String] = []
        if let search { params.append("search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") }
        if let category { params.append("category=\(category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") }
        if !params.isEmpty { path += "?" + params.joined(separator: "&") }
        let req = try makeRequest(path)
        return try await perform(req)
    }

    func createProduct(_ input: ProductInput) async throws -> Product {
        let req = try makeRequest("/products", method: "POST", body: input)
        return try await perform(req)
    }

    func updateProduct(id: String, input: ProductInput) async throws -> Product {
        let req = try makeRequest("/products/\(id)", method: "PATCH", body: input)
        return try await perform(req)
    }

    func deleteProduct(id: String) async throws {
        let req = try makeRequest("/products/\(id)", method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.serverError("Delete failed")
        }
    }

    // MARK: - Orders

    func fetchOrders(limit: Int = 50) async throws -> [Order] {
        let req = try makeRequest("/orders?limit=\(limit)")
        return try await perform(req)
    }

    func createOrder(_ order: CreateOrderRequest) async throws -> Order {
        let req = try makeRequest("/orders", method: "POST", body: order)
        return try await perform(req)
    }
}
