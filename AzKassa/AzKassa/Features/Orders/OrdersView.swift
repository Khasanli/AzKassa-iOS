import SwiftUI

struct OrdersView: View {
    @StateObject private var vm = OrdersViewModel()

    var body: some View {
        NavigationStack {
            List(vm.orders) { order in
                NavigationLink(destination: OrderDetailView(order: order)) {
                    OrderRow(order: order)
                }
            }
            .navigationTitle("Sifarişlər")
            .refreshable { await vm.load() }
            .task { await vm.load() }
        }
    }
}

struct OrderRow: View {
    let order: Order

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(order.number).font(.subheadline.bold())
                Text("\(order.items.count) məhsul · \(order.payMethod == "cash" ? "Nağd" : "Kart")")
                    .font(.caption).foregroundColor(.secondary)
                Text(String(order.createdAt.prefix(16)).replacingOccurrences(of: "T", with: " "))
                    .font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            Text(String(format: "%.2f ₼", order.total))
                .font(.subheadline.bold()).foregroundColor(Color("BrandColor"))
        }
        .padding(.vertical, 4)
    }
}

struct OrderDetailView: View {
    let order: Order

    var body: some View {
        List {
            Section("Ümumi") {
                LabeledContent("Nömrə", value: order.number)
                LabeledContent("Məbləğ", value: String(format: "%.2f ₼", order.total))
                LabeledContent("Ödəniş", value: order.payMethod == "cash" ? "Nağd" : "Kart")
                LabeledContent("Tarix", value: String(order.createdAt.prefix(16)).replacingOccurrences(of: "T", with: " "))
            }
            Section("Məhsullar (\(order.items.count))") {
                ForEach(order.items) { item in
                    HStack {
                        Text(item.name).font(.subheadline)
                        Spacer()
                        Text("×\(Int(item.qty))").foregroundColor(.secondary).font(.caption)
                        Text(String(format: "%.2f ₼", item.price)).font(.subheadline.bold())
                    }
                }
            }
        }
        .navigationTitle(order.number)
        .navigationBarTitleDisplayMode(.inline)
    }
}

@MainActor
final class OrdersViewModel: ObservableObject {
    @Published var orders: [Order] = []

    func load() async {
        orders = (try? await APIService.shared.fetchOrders()) ?? []
    }
}
