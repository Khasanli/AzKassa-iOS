import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Logo
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("BrandColor"))
                        .frame(width: 72, height: 72)
                        .overlay(
                            Text("AZ")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        )
                    Text("AzKassa")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Biznes idarəetmə sistemi")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Form
                VStack(spacing: 16) {
                    TextField("E-poçt", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                    SecureField("Şifrə", text: $password)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                    if let error = authStore.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task { await authStore.login(email: email, password: password) }
                    } label: {
                        Group {
                            if authStore.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Daxil ol")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color("BrandColor"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(authStore.isLoading || email.isEmpty || password.isEmpty)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
    }
}
