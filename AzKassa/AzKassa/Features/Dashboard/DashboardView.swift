import SwiftUI

struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()
    @EnvironmentObject var authStore: AuthStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dashboard")
                                .font(.appTitle)
                                .foregroundColor(.slate900)
                            if let name = authStore.currentUser?.companyName {
                                Text(name)
                                    .font(.appCaption)
                                    .foregroundColor(.slate500)
                            }
                        }
                        Spacer()
                        // Avatar
                        Circle()
                            .fill(LinearGradient(colors: [Color.brand, Color(hex: "#818CF8")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(authStore.currentUser?.fullName.prefix(2).uppercased() ?? "AZ")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color.white)

                    Divider()

                    VStack(spacing: 16) {
                        // Stats grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(
                                title: "Bugünkü satış",
                                value: String(format: "%.2f ₼", vm.todaySales),
                                icon: "chart.line.uptrend.xyaxis",
                                color: Color(hex: "#10B981"),
                                bgColor: Color(hex: "#ECFDF5")
                            )
                            StatCard(
                                title: "Sifarişlər",
                                value: "\(vm.orderCount)",
                                icon: "cart.fill",
                                color: Color.brand,
                                bgColor: Color.brandLight
                            )
                            StatCard(
                                title: "Məhsullar",
                                value: "\(vm.productCount)",
                                icon: "shippingbox.fill",
                                color: Color(hex: "#F59E0B"),
                                bgColor: Color(hex: "#FFFBEB")
                            )
                            StatCard(
                                title: "Az stok",
                                value: "\(vm.lowStockCount)",
                                icon: "exclamationmark.triangle.fill",
                                color: Color(hex: "#EF4444"),
                                bgColor: Color(hex: "#FEF2F2")
                            )
                        }
                        .padding(.horizontal, 16)

                        // Recent orders section
                        if !vm.recentOrders.isEmpty {
                            VStack(spacing: 0) {
                                AKSectionHeader(title: "Son Sifarişlər")

                                AKCard {
                                    VStack(spacing: 0) {
                                        ForEach(Array(vm.recentOrders.prefix(5).enumerated()), id: \.element.id) { idx, order in
                                            HStack(spacing: 12) {
                                                // Number badge
                                                Text(order.number)
                                                    .font(.appMono)
                                                    .foregroundColor(.brand)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.brandLight)
                                                    .cornerRadius(6)

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("\(order.items.count) məhsul")
                                                        .font(.appCaption)
                                                        .foregroundColor(.slate700)
                                                    Text(String(order.createdAt.prefix(10)))
                                                        .font(.system(size: 11))
                                                        .foregroundColor(.slate400)
                                                }

                                                Spacer()

                                                VStack(alignment: .trailing, spacing: 2) {
                                                    Text(String(format: "%.2f ₼", order.total))
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(.slate900)
                                                    Text(order.payMethod == "cash" ? "Nağd" : "Kart")
                                                        .font(.system(size: 11))
                                                        .foregroundColor(.slate400)
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)

                                            if idx < min(vm.recentOrders.count, 5) - 1 {
                                                Divider().padding(.leading, 16)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .background(Color.appBg)
            .navigationBarHidden(true)
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
    let bgColor: Color

    var body: some View {
        AKCard {
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(bgColor)
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: icon).foregroundColor(color).font(.system(size: 15)))

                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.slate900)

                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.slate500)
                    .lineLimit(1)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
