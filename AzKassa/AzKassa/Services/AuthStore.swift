import Foundation

@MainActor
final class AuthStore: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUser: AuthUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let tokenKey = "mkassa_token"
    private let userKey  = "mkassa_auth_user"

    init() {
        if let token = UserDefaults.standard.string(forKey: tokenKey), !token.isEmpty {
            isLoggedIn = true
            if let data = UserDefaults.standard.data(forKey: userKey) {
                currentUser = try? JSONDecoder().decode(AuthUser.self, from: data)
            }
        }
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIService.shared.login(email: email, password: password)
            save(token: response.token, user: response.user)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        currentUser = nil
        isLoggedIn = false
    }

    private func save(token: String, user: AuthUser?) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        if let user, let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userKey)
            currentUser = user
        }
        isLoggedIn = true
    }
}
