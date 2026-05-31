import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authStore: AuthStore
    @StateObject private var vm = SettingsViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Parametrlər").font(.appTitle).foregroundColor(.slate900)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(Color.white)

                Divider()

                List {
                    // Profile section
                    Section {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(LinearGradient(colors: [Color.brand, Color(hex: "#818CF8")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text(authStore.currentUser?.fullName.prefix(2).uppercased() ?? "AZ")
                                        .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(authStore.currentUser?.fullName ?? "İstifadəçi")
                                    .font(.system(size: 15, weight: .semibold)).foregroundColor(.slate900)
                                Text(authStore.currentUser?.email ?? "")
                                    .font(.system(size: 13)).foregroundColor(.slate500)
                                Text(authStore.currentUser?.companyName ?? "")
                                    .font(.system(size: 12)).foregroundColor(.slate400)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.white)

                    // General settings
                    Section("Ümumi") {
                        SettingsRow(icon: "dollarsign.circle", label: "Valyuta", value: vm.currency, color: Color(hex: "#10B981")) {
                            vm.showCurrencyPicker = true
                        }
                        SettingsRow(icon: "globe", label: "Dil", value: "Azərbaycan", color: .brand) {}
                        SettingsRow(icon: "percent", label: "ƏDV dərəcəsi", value: "\(Int(vm.vatRate))%", color: Color(hex: "#F59E0B")) {
                            vm.showVatEditor = true
                        }
                    }
                    .listRowBackground(Color.white)

                    // Staff management
                    Section("İstifadəçilər") {
                        NavigationLink {
                            StaffManagementView()
                        } label: {
                            SettingsRowLabel(icon: "person.2.fill", label: "İşçi hesabları", color: Color(hex: "#8B5CF6"))
                        }
                    }
                    .listRowBackground(Color.white)

                    // Print settings
                    Section("Çap") {
                        Toggle(isOn: $vm.autoPrint) {
                            SettingsRowLabel(icon: "printer.fill", label: "Avtomatik çap", color: .slate600)
                        }
                        .tint(Color.brand)
                        SettingsRow(icon: "doc.text", label: "Altbilgi mətni", value: vm.footerText.isEmpty ? "—" : vm.footerText, color: .slate500) {
                            vm.showFooterEditor = true
                        }
                    }
                    .listRowBackground(Color.white)

                    // Logout
                    Section {
                        Button {
                            authStore.logout()
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.red)
                                Text("Çıxış").foregroundColor(.red)
                                    .font(.system(size: 15, weight: .semibold))
                            }
                        }
                    }
                    .listRowBackground(Color.white)
                }
                .listStyle(.insetGrouped)
                .background(Color.appBg)
            }
            .background(Color.appBg)
            .navigationBarHidden(true)
            .confirmationDialog("Valyuta", isPresented: $vm.showCurrencyPicker) {
                ForEach(["₼ AZN", "$ USD", "€ EUR", "₺ TRY"], id: \.self) { c in
                    Button(c) { vm.currency = c }
                }
            }
            .alert("ƏDV dərəcəsi", isPresented: $vm.showVatEditor) {
                TextField("18", value: $vm.vatRate, format: .number)
                    .keyboardType(.decimalPad)
                Button("Saxla") { UserDefaults.standard.set(vm.vatRate, forKey: "vat_rate") }
                Button("Ləğv et", role: .cancel) {}
            }
            .alert("Altbilgi mətni", isPresented: $vm.showFooterEditor) {
                TextField("məs. Alış-veriş üçün...", text: $vm.footerText)
                Button("Saxla") { UserDefaults.standard.set(vm.footerText, forKey: "receipt_footer") }
                Button("Ləğv et", role: .cancel) {}
            }
        }
    }
}

struct SettingsRowLabel: View {
    let icon: String; let label: String; let color: Color
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 6).fill(color).frame(width: 28, height: 28)
                .overlay(Image(systemName: icon).font(.system(size: 13)).foregroundColor(.white))
            Text(label).font(.appBody).foregroundColor(.slate900)
        }
    }
}

struct SettingsRow: View {
    let icon: String; let label: String; let value: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                SettingsRowLabel(icon: icon, label: label, color: color)
                Spacer()
                Text(value).font(.appBody).foregroundColor(.slate400)
                Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(.slate300)
            }
        }
        .buttonStyle(.plain)
    }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var currency = "₼ AZN"
    @Published var vatRate: Double = 18
    @Published var autoPrint = false
    @Published var footerText = ""
    @Published var anthropicKey = ""
    @Published var showCurrencyPicker = false
    @Published var showVatEditor = false
    @Published var showFooterEditor = false

    init() {
        currency = UserDefaults.standard.string(forKey: "currency") ?? "₼ AZN"
        vatRate = UserDefaults.standard.double(forKey: "vat_rate").nonZero ?? 18
        autoPrint = UserDefaults.standard.bool(forKey: "auto_print")
        footerText = UserDefaults.standard.string(forKey: "receipt_footer") ?? ""
        anthropicKey = UserDefaults.standard.string(forKey: "anthropic_api_key") ?? ""
    }
}

extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}
