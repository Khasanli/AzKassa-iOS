import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case notFound
    case serverError(String)
    case decodingError(Error)
    case offline

    var errorDescription: String? {
        switch self {
        case .unauthorized:    return "Giriş tələb olunur"
        case .notFound:        return "Tapılmadı"
        case .serverError(let m): return m
        case .decodingError(let e): return "Məlumat xətası: \(e.localizedDescription)"
        case .offline:         return "Server əlçatan deyil"
        }
    }
}

final class APIService {
    static let shared = APIService()
    private init() {}

    // Simulator hits Mac localhost; device hits the production server.
    private var baseURL: String {
        #if targetEnvironment(simulator)
        return "http://localhost:3001/api"
        #else
        return "http://178.105.243.22/api"
        #endif
    }

    var token: String? {
        UserDefaults.standard.string(forKey: "mkassa_token")
    }

    private func makeRequest(_ path: String, method: String = "GET", body: Encodable? = nil) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else { throw APIError.serverError("Invalid URL") }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 10
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body { req.httpBody = try JSONEncoder().encode(body) }
        return req
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.offline
        }
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

    // MARK: - Products

    func fetchProducts(search: String? = nil, category: String? = nil) async throws -> [Product] {
        var path = "/products"
        var params: [String] = []
        if let s = search { params.append("search=\(s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") }
        if let c = category { params.append("category=\(c.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") }
        if !params.isEmpty { path += "?" + params.joined(separator: "&") }
        return try await perform(makeRequest(path))
    }

    func createProduct(_ input: ProductInput) async throws -> Product {
        try await perform(makeRequest("/products", method: "POST", body: input))
    }

    func updateProduct(id: String, input: ProductInput) async throws -> Product {
        try await perform(makeRequest("/products/\(id)", method: "PATCH", body: input))
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
        try await perform(makeRequest("/orders?limit=\(limit)"))
    }

    func createOrder(_ order: CreateOrderRequest) async throws -> Order {
        try await perform(makeRequest("/orders", method: "POST", body: order))
    }

    // MARK: - Staff

    func fetchStaff() async throws -> [StaffMember] {
        try await perform(makeRequest("/auth/staff"))
    }

    func createStaff(username: String, fullName: String, password: String, permissions: [String]) async throws -> StaffMember {
        struct Body: Encodable { let username: String; let password: String; let fullName: String; let permissions: [String] }
        return try await perform(makeRequest("/auth/staff", method: "POST", body: Body(username: username, password: password, fullName: fullName, permissions: permissions)))
    }

    func deleteStaff(id: String) async throws {
        let req = try makeRequest("/auth/staff/\(id)", method: "DELETE")
        _ = try await URLSession.shared.data(for: req)
    }
}
