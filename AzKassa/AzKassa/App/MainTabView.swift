import SwiftUI

// UITabBarController directly — guaranteed native glass effect + exact icon size control

struct MainTabView: UIViewControllerRepresentable {
    @EnvironmentObject var authStore: AuthStore

    func makeUIViewController(context: Context) -> UITabBarController {
        let tabVC = UITabBarController()

        let iconSize: CGFloat = 14
        let cfg = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .medium)

        func tab<V: View>(_ view: V, icon: String, title: String) -> UIViewController {
            let vc = UIHostingController(rootView: view.environmentObject(authStore))
            vc.tabBarItem = UITabBarItem(
                title: title,
                image: UIImage(systemName: icon, withConfiguration: cfg),
                selectedImage: UIImage(systemName: icon, withConfiguration: cfg)
            )
            return vc
        }

        tabVC.viewControllers = [
            tab(DashboardView(),  icon: "chart.bar.fill",           title: "Dashboard"),
            tab(POSView(),        icon: "cart.fill",                 title: "Satış"),
            tab(ProductsView(),   icon: "shippingbox.fill",          title: "Məhsullar"),
            tab(InvoicesView(),   icon: "doc.text.fill",             title: "Qəbzlər"),
            tab(ReportsView(),    icon: "chart.line.uptrend.xyaxis", title: "Hesabat"),
            tab(SettingsView(),   icon: "gearshape.fill",            title: "Parametr"),
        ]

        // Native glass appearance + small label font
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        let item = UITabBarItemAppearance()
        let font = UIFont.systemFont(ofSize: 9, weight: .medium)
        item.normal.titleTextAttributes   = [.font: font, .foregroundColor: UIColor.systemGray]
        item.selected.titleTextAttributes = [.font: font]
        appearance.stackedLayoutAppearance      = item
        appearance.inlineLayoutAppearance       = item
        appearance.compactInlineLayoutAppearance = item

        tabVC.tabBar.standardAppearance   = appearance
        tabVC.tabBar.scrollEdgeAppearance = appearance
        tabVC.tabBar.tintColor            = UIColor(Color.brand)

        return tabVC
    }

    func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {}
}
