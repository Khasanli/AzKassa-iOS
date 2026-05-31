import SwiftUI

struct InvoicesView: View {
    @StateObject private var vm = InvoicesViewModel()
    @State private var selectedOrder: Order?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with KPI
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Satış › Qəbzlər")
                                .font(.system(size: 11)).foregroundColor(.slate400)
                            Text("Qəbzlər")
                                .font(.appTitle).foregroundColor(.slate900)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)

                    // Summary cards
                    HStack(spacing: 10) {
                        MiniStatCard(label: "Bu gün", value: String(format: "%.2f ₼", vm.todaySales), color: Color(hex: "#10B981"))
                        MiniStatCard(label: "💵 Nağd", value: String(format: "%.2f ₼", vm.cashTotal), color: Color(hex: "#F59E0B"))
                        MiniStatCard(label: "💳 Kart", value: String(format: "%.2f ₼", vm.cardTotal), color: .brand)
                    }
                    .padding(.horizontal, 16).padding(.bottom, 12)
                }
                .background(Color.white)

                Divider()

                // Search + filter
                HStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundColor(.slate400).font(.system(size: 14))
                        TextField("Qəbz nömrəsi...", text: $vm.search)
                            .font(.appBody).autocapitalization(.none)
                        if !vm.search.isEmpty {
                            Button { vm.search = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.slate300)
                            }
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(Color.white).cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.slate200, lineWidth: 1))

                    Menu {
                        Button("Hamısı") { vm.payFilter = nil }
                        Button("Nağd") { vm.payFilter = "cash" }
                        Button("Kart") { vm.payFilter = "card" }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease")
                            Text(vm.payFilter == nil ? "Hamısı" : vm.payFilter == "cash" ? "Nağd" : "Kart")
                                .font(.system(size: 13))
                        }
                        .padding(.horizontal, 12).padding(.vertical, 9)
                        .background(Color.white).foregroundColor(.slate600).cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.slate200, lineWidth: 1))
                    }
                }
                .padding(12).background(Color.appBg)

                // List
                List(vm.filteredOrders) { order in
                    Button { selectedOrder = order } label: {
                        InvoiceRow(order: order)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.white)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }
                .listStyle(.plain)
                .background(Color.appBg)
                .refreshable { await vm.load() }
            }
            .background(Color.appBg)
            .navigationBarHidden(true)
            .sheet(item: $selectedOrder) { order in
                InvoiceDetailSheet(order: order)
            }
            .task { await vm.load() }
        }
    }
}

struct MiniStatCard: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 11)).foregroundColor(.slate500)
            Text(value).font(.system(size: 14, weight: .bold)).foregroundColor(.slate900)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.3), lineWidth: 1))
    }
}

struct InvoiceRow: View {
    let order: Order
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(order.number)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.brand)
                HStack(spacing: 4) {
                    Text("\(order.items.count) məhsul").font(.system(size: 12)).foregroundColor(.slate600)
                    Text("·").foregroundColor(.slate300)
                    Image(systemName: order.payMethod == "cash" ? "banknote" : "creditcard")
                        .font(.system(size: 10)).foregroundColor(.slate400)
                    Text(order.payMethod == "cash" ? "Nağd" : "Kart")
                        .font(.system(size: 12)).foregroundColor(.slate400)
                }
                Text(String(order.createdAt.prefix(16)).replacingOccurrences(of: "T", with: " "))
                    .font(.system(size: 11)).foregroundColor(.slate400)
            }
            Spacer()
            Text(String(format: "%.2f ₼", order.total))
                .font(.system(size: 15, weight: .bold)).foregroundColor(.slate900)
            Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(.slate300)
        }
        .padding(.vertical, 10)
    }
}

struct InvoiceDetailSheet: View {
    let order: Order
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledRow(label: "Qəbz nömrəsi", value: order.number)
                    LabeledRow(label: "Tarix", value: String(order.createdAt.prefix(16)).replacingOccurrences(of: "T", with: " "))
                    LabeledRow(label: "Ödəniş üsulu", value: order.payMethod == "cash" ? "💵 Nağd" : "💳 Kart")
                    HStack {
                        Text("Cəmi").font(.appBody).foregroundColor(.slate500)
                        Spacer()
                        Text(String(format: "%.2f ₼", order.total))
                            .font(.system(size: 16, weight: .bold)).foregroundColor(.brand)
                    }
                } header: { Text("Qəbz məlumatı").font(.system(size: 11)).foregroundColor(.slate500) }
                  .listRowBackground(Color.white)

                Section {
                    ForEach(order.items) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.slate900)
                                Text("×\(Int(item.qty)) \(item.unit)").font(.system(size: 11)).foregroundColor(.slate400)
                            }
                            Spacer()
                            Text(String(format: "%.2f ₼", item.price))
                                .font(.system(size: 13, weight: .bold)).foregroundColor(.slate900)
                        }
                    }
                } header: { Text("Məhsullar (\(order.items.count))").font(.system(size: 11)).foregroundColor(.slate500) }
                  .listRowBackground(Color.white)
            }
            .listStyle(.insetGrouped)
            .background(Color.appBg)
            .navigationTitle(order.number)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Bağla") { dismiss() }.foregroundColor(.brand)
                }
            }
        }
    }
}

@MainActor
final class InvoicesViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var search = ""
    @Published var payFilter: String? = nil

    var filteredOrders: [Order] {
        orders.filter { o in
            let matchSearch = search.isEmpty || o.number.localizedCaseInsensitiveContains(search)
            let matchPay = payFilter == nil || o.payMethod == payFilter
            return matchSearch && matchPay
        }
    }

    var todaySales: Double {
        let today = String(ISO8601DateFormatter().string(from: Date()).prefix(10))
        return orders.filter { $0.createdAt.hasPrefix(today) }.reduce(0) { $0 + $1.total }
    }
    var cashTotal: Double { filteredOrders.filter { $0.payMethod == "cash" }.reduce(0) { $0 + $1.total } }
    var cardTotal: Double { filteredOrders.filter { $0.payMethod == "card" }.reduce(0) { $0 + $1.total } }

    func load() async {
        orders = (try? await APIService.shared.fetchOrders(limit: 200)) ?? []
    }
}
