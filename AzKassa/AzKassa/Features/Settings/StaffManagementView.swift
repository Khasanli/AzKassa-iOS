import SwiftUI

struct StaffManagementView: View {
    @StateObject private var vm = StaffViewModel()

    var body: some View {
        List {
            if vm.staff.isEmpty && !vm.isLoading {
                VStack(spacing: 10) {
                    Image(systemName: "person.slash").font(.system(size: 40)).foregroundColor(.slate300)
                    Text("İşçi yoxdur").font(.system(size: 15, weight: .semibold)).foregroundColor(.slate500)
                    Text("Yeni işçi əlavə edin").font(.appBody).foregroundColor(.slate400)
                }
                .frame(maxWidth: .infinity).padding(40)
            }
            ForEach(vm.staff) { member in
                StaffRow(member: member)
            }
            .onDelete { idx in
                Task { for i in idx { await vm.delete(vm.staff[i]) } }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("İşçi hesabları")
        .navigationBarTitleDisplayMode(.inline)
        .akNavigationStyle()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { vm.showAdd = true } label: { Image(systemName: "plus") }
                    .foregroundColor(.brand)
            }
        }
        .sheet(isPresented: $vm.showAdd) { AddStaffView(vm: vm) }
        .task { await vm.load() }
        .overlay { if vm.isLoading { ProgressView().tint(.brand) } }
    }
}

struct StaffRow: View {
    let member: StaffMember
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.brandLight)
                .frame(width: 38, height: 38)
                .overlay(Text(member.fullName.prefix(1).uppercased()).font(.system(size: 14, weight: .bold)).foregroundColor(.brand))
            VStack(alignment: .leading, spacing: 2) {
                Text(member.fullName).font(.system(size: 14, weight: .semibold)).foregroundColor(.slate900)
                Text("@\(member.username)").font(.system(size: 12, design: .monospaced)).foregroundColor(.slate400)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                ForEach(member.permissions.prefix(2), id: \.self) { p in
                    Text(permLabel(p)).font(.system(size: 10)).foregroundColor(.brand)
                        .padding(.horizontal, 6).padding(.vertical, 2).background(Color.brandLight).cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
    func permLabel(_ p: String) -> String {
        ["sales": "Satış", "inventory": "Anbar", "reports": "Hesabat", "settings": "Parametr", "tables": "Masalar"][p] ?? p
    }
}

struct AddStaffView: View {
    @ObservedObject var vm: StaffViewModel
    @Environment(\.dismiss) var dismiss
    @State private var username = ""
    @State private var fullName = ""
    @State private var password = ""
    @State private var selectedPerms: Set<String> = []

    let allPerms = ["sales", "inventory", "reports", "tables", "settings"]
    let permNames = ["sales": "Satış", "inventory": "Anbar", "reports": "Hesabat", "tables": "Masalar", "settings": "Parametrlər"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Məlumatlar") {
                    TextField("Tam ad", text: $fullName)
                    TextField("İstifadəçi adı", text: $username).autocapitalization(.none)
                    SecureField("Şifrə (min 4 simvol)", text: $password)
                }
                .listRowBackground(Color.white)

                Section("İcazələr") {
                    ForEach(allPerms, id: \.self) { perm in
                        Toggle(permNames[perm] ?? perm, isOn: Binding(
                            get: { selectedPerms.contains(perm) },
                            set: { if $0 { selectedPerms.insert(perm) } else { selectedPerms.remove(perm) } }
                        ))
                        .tint(Color.brand)
                    }
                }
                .listRowBackground(Color.white)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Yeni işçi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Ləğv") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Saxla") {
                        Task {
                            await vm.create(username: username, fullName: fullName, password: password, permissions: Array(selectedPerms))
                            dismiss()
                        }
                    }
                    .disabled(username.isEmpty || fullName.isEmpty || password.count < 4)
                    .foregroundColor(.brand)
                }
            }
        }
    }
}

struct StaffMember: Codable, Identifiable {
    let id: String
    let username: String
    let fullName: String
    let permissions: [String]
}

@MainActor
final class StaffViewModel: ObservableObject {
    @Published var staff: [StaffMember] = []
    @Published var isLoading = false
    @Published var showAdd = false

    func load() async {
        isLoading = true
        if let data = try? await APIService.shared.fetchStaff() { staff = data }
        isLoading = false
    }

    func create(username: String, fullName: String, password: String, permissions: [String]) async {
        if let member = try? await APIService.shared.createStaff(username: username, fullName: fullName, password: password, permissions: permissions) {
            staff.insert(member, at: 0)
        }
    }

    func delete(_ member: StaffMember) async {
        try? await APIService.shared.deleteStaff(id: member.id)
        staff.removeAll { $0.id == member.id }
    }
}
