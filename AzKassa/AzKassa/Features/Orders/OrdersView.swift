import SwiftUI

struct OrdersView: View {
    @StateObject private var vm = OrdersViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Satış › Sifarişlər")
                            .font(.system(size: 11))
                            .foregroundColor(.slate400)
                        Text("Sifarişlər")
                            .font(.appTitle)
                            .foregroundColor(.slate900)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(Color.white)

                Divider()

                List(vm.orders) { order in
                    NavigationLink(destination: OrderDetailView(order: order)) {
                        OrderRow(order: order)
                    }
                    .listRowBackground(Color.white)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }
                .listStyle(.plain)
                .background(Color.appBg)
                .refreshable { await vm.load() }
            }
            .background(Color.appBg)
            .navigationBarHidden(true)
            .task { await vm.load() }
        }
    }
}

struct OrderRow: View {
    let order: Order

    var body: some View {
        HStack(spacing: 12) {
            // CHK badge
            Text(order.number)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.brand)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.brandLight)
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(order.items.count) məhsul")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.slate700)
                HStack(spacing: 4) {
                    Image(systemName: order.payMethod == "cash" ? "banknote" : "creditcard")
                        .font(.system(size: 9))
                    Text(order.payMethod == "cash" ? "Nağd" : "Kart")
                    Text("·")
                    Text(String(order.createdAt.prefix(10)))
                }
                .font(.system(size: 11))
                .foregroundColor(.slate400)
            }

            Spacer()

            Text(String(format: "%.2f ₼", order.total))
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.slate900)
        }
        .padding(.vertical, 10)
    }
}

struct OrderDetailView: View {
    let order: Order

    var body: some View {
        List {
            Section {
                LabeledRow(label: "Nömrə", value: order.number)
                LabeledRow(label: "Ödəniş", value: order.payMethod == "cash" ? "💵 Nağd" : "💳 Kart")
                LabeledRow(label: "Tarix", value: String(order.createdAt.prefix(16)).replacingOccurrences(of: "T", with: " "))
                HStack {
                    Text("Cəmi").font(.appBody).foregroundColor(.slate700)
                    Spacer()
                    Text(String(format: "%.2f ₼", order.total))
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.brand)
                }
            } header: { Text("Ümumi məlumat").font(.system(size: 11, weight: .semibold)).foregroundColor(.slate500) }
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
                    .padding(.vertical, 2)
                }
            } header: { Text("Məhsullar (\(order.items.count))").font(.system(size: 11, weight: .semibold)).foregroundColor(.slate500) }
              .listRowBackground(Color.white)
        }
        .listStyle(.insetGrouped)
        .background(Color.appBg)
        .navigationTitle(order.number)
        .navigationBarTitleDisplayMode(.inline)
        .akNavigationStyle()
    }
}

struct LabeledRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.appBody).foregroundColor(.slate500)
            Spacer()
            Text(value).font(.system(size: 13, weight: .medium)).foregroundColor(.slate800)
        }
    }
}

@MainActor
final class OrdersViewModel: ObservableObject {
    @Published var orders: [Order] = []
    func load() async {
        orders = (try? await APIService.shared.fetchOrders()) ?? []
    }
}
