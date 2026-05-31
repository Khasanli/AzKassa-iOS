import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }

            POSView()
                .tabItem {
                    Label("Satış", systemImage: "cart.fill")
                }

            ProductsView()
                .tabItem {
                    Label("Məhsullar", systemImage: "shippingbox.fill")
                }

            OrdersView()
                .tabItem {
                    Label("Sifarişlər", systemImage: "list.bullet.rectangle.fill")
                }
        }
        .tint(Color("BrandColor"))
    }
}
