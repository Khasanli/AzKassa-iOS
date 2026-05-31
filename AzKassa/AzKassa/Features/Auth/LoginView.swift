import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)

                    // Logo — matches web sidebar logo
                    VStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.brand)
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text("AZ")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            )

                        VStack(spacing: 4) {
                            Text("AzKassa")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.slate900)
                            Text("Biznes idarəetmə sistemi")
                                .font(.appBody)
                                .foregroundColor(.slate500)
                        }
                    }
                    .padding(.bottom, 40)

                    // Card
                    AKCard {
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("E-poçt")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.slate700)
                                AKTextField(placeholder: "email@example.com", text: $email, keyboardType: .emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Şifrə")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.slate700)
                                AKTextField(placeholder: "••••••", text: $password, isSecure: true)
                            }

                            if let error = authStore.errorMessage {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                    Text(error)
                                }
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#DC2626"))
                                .padding(10)
                                .background(Color(hex: "#FEF2F2"))
                                .cornerRadius(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            AKPrimaryButton(
                                "Daxil ol",
                                isLoading: authStore.isLoading,
                                isDisabled: email.isEmpty || password.isEmpty
                            ) {
                                Task { await authStore.login(email: email, password: password) }
                            }
                            .padding(.top, 4)
                        }
                        .padding(24)
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
            }
        }
    }
}
