import SwiftUI

struct MainTabView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white

        // Smaller icon + label for 6 tabs
        let itemAppearance = UITabBarItemAppearance()
        let smallFont = UIFont.systemFont(ofSize: 9, weight: .medium)
        itemAppearance.normal.titleTextAttributes   = [.font: smallFont, .foregroundColor: UIColor.systemGray]
        itemAppearance.selected.titleTextAttributes = [.font: smallFont, .foregroundColor: UIColor(Color.brand)]
        itemAppearance.normal.iconColor   = .systemGray
        itemAppearance.selected.iconColor = UIColor(Color.brand)
        appearance.stackedLayoutAppearance   = itemAppearance
        appearance.inlineLayoutAppearance    = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance   = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = UIColor(Color.brand)
    }

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill").environment(\.imageScale, .small) }

            POSView()
                .tabItem { Label("Satış", systemImage: "cart.fill").environment(\.imageScale, .small) }

            ProductsView()
                .tabItem { Label("Məhsullar", systemImage: "shippingbox.fill").environment(\.imageScale, .small) }

            InvoicesView()
                .tabItem { Label("Qəbzlər", systemImage: "doc.text.fill").environment(\.imageScale, .small) }

            ReportsView()
                .tabItem { Label("Hesabat", systemImage: "chart.line.uptrend.xyaxis").environment(\.imageScale, .small) }

            SettingsView()
                .tabItem { Label("Parametr", systemImage: "gearshape.fill").environment(\.imageScale, .small) }
        }
        .tint(Color.brand)
    }
}
