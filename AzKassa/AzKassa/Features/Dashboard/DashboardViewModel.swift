import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var recentOrders: [Order] = []
    @Published var products: [Product] = []

    var todaySales: Double {
        let today = String(ISO8601DateFormatter().string(from: Date()).prefix(10))
        return recentOrders
            .filter { $0.createdAt.hasPrefix(today) }
            .reduce(0) { $0 + $1.total }
    }

    var orderCount: Int { recentOrders.count }
    var productCount: Int { products.count }
    var lowStockCount: Int { products.filter { $0.isLowStock }.count }

    func load() async {
        async let orders = try? APIService.shared.fetchOrders(limit: 20)
        async let prods = try? APIService.shared.fetchProducts()
        recentOrders = (await orders) ?? []
        products = (await prods) ?? []
    }
}
