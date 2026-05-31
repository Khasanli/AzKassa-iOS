import SwiftUI

// Demo credentials — same account used on the web app
private let demoEmail    = "demo@azkassa.az"
private let demoPassword = "demo1234"

struct LoginView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var email    = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            Color(hex: "#F8FAFC").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)

                    // Logo
                    VStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "#4F46E5"))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text("AZ")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        VStack(spacing: 4) {
                            Text("AzKassa")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(Color(hex: "#0F172A"))
                            Text("Biznes idarəetmə sistemi")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#64748B"))
                        }
                    }
                    .padding(.bottom, 36)

                    // Login card
                    VStack(spacing: 16) {
                        // Email
                        VStack(alignment: .leading, spacing: 6) {
                            Text("E-poçt")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "#334155"))
                            textInput(placeholder: "email@example.com", text: $email, keyboard: .emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }

                        // Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Şifrə")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "#334155"))
                            SecureField("••••••", text: $password)
                                .padding(.horizontal, 12).padding(.vertical, 10)
                                .background(Color(hex: "#F1F5F9"))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#E2E8F0"), lineWidth: 1))
                        }

                        // Error
                        if let error = authStore.errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(error)
                            }
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#DC2626"))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "#FEF2F2"))
                            .cornerRadius(8)
                        }

                        // Login button
                        Button {
                            Task { await authStore.login(email: email, password: password) }
                        } label: {
                            Group {
                                if authStore.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Daxil ol")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity).frame(height: 44)
                            .background(email.isEmpty || password.isEmpty ? Color(hex: "#CBD5E1") : Color(hex: "#4F46E5"))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(authStore.isLoading || email.isEmpty || password.isEmpty)
                        .padding(.top, 4)
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 24)

                    // Demo account section
                    VStack(spacing: 10) {
                        HStack {
                            Rectangle().fill(Color(hex: "#E2E8F0")).frame(height: 1)
                            Text("Demo hesab").font(.system(size: 12)).foregroundColor(Color(hex: "#94A3B8")).padding(.horizontal, 8)
                            Rectangle().fill(Color(hex: "#E2E8F0")).frame(height: 1)
                        }
                        .padding(.top, 20)

                        Button {
                            email    = demoEmail
                            password = demoPassword
                        } label: {
                            HStack(spacing: 10) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "#EEF2FF"))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(hex: "#4F46E5"))
                                    )
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Demo Mağaza")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(hex: "#334155"))
                                    Text(demoEmail)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(Color(hex: "#94A3B8"))
                                }
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundColor(Color(hex: "#4F46E5"))
                                    .font(.system(size: 18))
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#E2E8F0"), lineWidth: 1))
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
    }

    @ViewBuilder
    private func textInput(placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard)
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(Color(hex: "#F1F5F9"))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#E2E8F0"), lineWidth: 1))
    }
}
