import SwiftUI

struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Stats row
                    HStack(spacing: 12) {
                        StatCard(title: "Bugünkü satış", value: String(format: "%.2f ₼", vm.todaySales), icon: "chart.line.uptrend.xyaxis", color: .green)
                        StatCard(title: "Sifarişlər", value: "\(vm.orderCount)", icon: "cart", color: Color("BrandColor"))
                    }
                    HStack(spacing: 12) {
                        StatCard(title: "Məhsullar", value: "\(vm.productCount)", icon: "shippingbox", color: .orange)
                        StatCard(title: "Az stok", value: "\(vm.lowStockCount)", icon: "exclamationmark.triangle", color: .red)
                    }

                    // Recent orders
                    if !vm.recentOrders.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Son sifarişlər")
                                .font(.headline)
                                .padding(.horizontal)
                            ForEach(vm.recentOrders.prefix(5)) { order in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(order.number).font(.subheadline.bold())
                                        Text(order.createdAt.prefix(10)).font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(String(format: "%.2f ₼", order.total))
                                        .font(.subheadline.bold()).foregroundColor(Color("BrandColor"))
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .refreshable { await vm.load() }
            .task { await vm.load() }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Spacer()
            }
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
