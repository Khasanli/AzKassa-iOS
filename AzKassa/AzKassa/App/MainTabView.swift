import SwiftUI

struct MainTabView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = UIColor(Color.brand)
    }

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }

            POSView()
                .tabItem { Label("Satış", systemImage: "cart.fill") }

            ProductsView()
                .tabItem { Label("Məhsullar", systemImage: "shippingbox.fill") }

            InvoicesView()
                .tabItem { Label("Qəbzlər", systemImage: "doc.text.fill") }

            ReportsView()
                .tabItem { Label("Hesabat", systemImage: "chart.line.uptrend.xyaxis") }

            SettingsView()
                .tabItem { Label("Parametr", systemImage: "gearshape.fill") }
        }
        .tint(Color.brand)
    }
}
