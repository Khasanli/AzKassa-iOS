import SwiftUI

private struct TabItem {
    let tag: Int
    let icon: String
    let label: String
}

private let tabs: [TabItem] = [
    TabItem(tag: 0, icon: "chart.bar.fill",           label: "Dashboard"),
    TabItem(tag: 1, icon: "cart.fill",                 label: "Satış"),
    TabItem(tag: 2, icon: "shippingbox.fill",          label: "Məhsullar"),
    TabItem(tag: 3, icon: "doc.text.fill",             label: "Qəbzlər"),
    TabItem(tag: 4, icon: "chart.line.uptrend.xyaxis", label: "Hesabat"),
    TabItem(tag: 5, icon: "gearshape.fill",            label: "Parametr"),
]

struct MainTabView: View {
    @State private var selected = 0

    var body: some View {
        VStack(spacing: 0) {
            // Content
            Group {
                switch selected {
                case 0: DashboardView()
                case 1: POSView()
                case 2: ProductsView()
                case 3: InvoicesView()
                case 4: ReportsView()
                case 5: SettingsView()
                default: DashboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Custom tab bar
            HStack(spacing: 0) {
                ForEach(tabs, id: \.tag) { tab in
                    Button {
                        selected = tab.tag
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 18, weight: .medium))
                                .frame(height: 22)
                            Text(tab.label)
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundColor(selected == tab.tag ? Color.brand : Color(hex: "#94A3B8"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
            .background(Color.white)
            .padding(.bottom, 2)
        }
        .ignoresSafeArea(edges: .bottom)
        .tint(Color.brand)
    }
}
