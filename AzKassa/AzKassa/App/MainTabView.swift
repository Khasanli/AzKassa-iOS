import SwiftUI

struct MainTabView: View {
    @State private var selected = 0

    // Icon names matching tab order
    private let iconNames = [
        "chart.bar.fill",
        "cart.fill",
        "shippingbox.fill",
        "doc.text.fill",
        "chart.line.uptrend.xyaxis",
        "gearshape.fill",
    ]

    var body: some View {
        TabView(selection: $selected) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
                .tag(0)

            POSView()
                .tabItem { Label("Satış", systemImage: "cart.fill") }
                .tag(1)

            ProductsView()
                .tabItem { Label("Məhsullar", systemImage: "shippingbox.fill") }
                .tag(2)

            InvoicesView()
                .tabItem { Label("Qəbzlər", systemImage: "doc.text.fill") }
                .tag(3)

            ReportsView()
                .tabItem { Label("Hesabat", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(4)

            SettingsView()
                .tabItem { Label("Parametr", systemImage: "gearshape.fill") }
                .tag(5)
        }
        .tint(Color.brand)
        .onAppear { resizeTabBarIcons() }
    }

    // Replace system tab bar images with smaller 18pt versions
    private func resizeTabBarIcons() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }

        func findTabBar(_ vc: UIViewController) -> UITabBar? {
            if let tb = (vc as? UITabBarController)?.tabBar { return tb }
            for child in vc.children { if let found = findTabBar(child) { return found } }
            return nil
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            guard let tabBar = findTabBar(root) else { return }
            let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
            for (index, item) in (tabBar.items ?? []).enumerated() {
                guard index < iconNames.count else { break }
                let img = UIImage(systemName: iconNames[index], withConfiguration: config)
                item.image         = img
                item.selectedImage = img
            }
        }
    }
}
