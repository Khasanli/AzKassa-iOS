import SwiftUI
import Charts

struct ReportsView: View {
    @StateObject private var vm = ReportsViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hesabatlar")
                            .font(.appTitle).foregroundColor(.slate900)
                    }
                    Spacer()
                    Button { Task { await vm.load() } } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15)).foregroundColor(.brand)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(Color.white)

                Divider()

                // Date filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(DateRange.allCases) { range in
                            POSCategoryChip(label: range.label, isSelected: vm.dateRange == range) {
                                vm.dateRange = range
                                Task { await vm.load() }
                            }
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                }
                .background(Color.appBg)

                ScrollView {
                    VStack(spacing: 16) {
                        // KPI Cards
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(title: "Ümumi gəlir", value: String(format: "%.2f ₼", vm.totalRevenue), icon: "banknote.fill", color: Color(hex: "#10B981"), bgColor: Color(hex: "#ECFDF5"))
                            StatCard(title: "Orta sifariş", value: String(format: "%.2f ₼", vm.avgOrder), icon: "cart.fill", color: .brand, bgColor: .brandLight)
                            StatCard(title: "Nağd ödəniş", value: String(format: "%.2f ₼", vm.cashTotal), icon: "banknote", color: Color(hex: "#F59E0B"), bgColor: Color(hex: "#FFFBEB"))
                            StatCard(title: "Kart ödəniş", value: String(format: "%.2f ₼", vm.cardTotal), icon: "creditcard.fill", color: Color(hex: "#8B5CF6"), bgColor: Color(hex: "#F5F3FF"))
                        }
                        .padding(.horizontal, 16)

                        // Sales trend chart
                        if !vm.salesByDay.isEmpty {
                            AKCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Satış trendi")
                                        .font(.system(size: 13, weight: .semibold)).foregroundColor(.slate700)

                                    Chart(vm.salesByDay) { day in
                                        BarMark(
                                            x: .value("Tarix", day.date),
                                            y: .value("Satış", day.total)
                                        )
                                        .foregroundStyle(Color.brand.gradient)
                                        .cornerRadius(4)
                                    }
                                    .frame(height: 160)
                                    .chartXAxis {
                                        AxisMarks(values: .stride(by: .day)) { _ in
                                            AxisGridLine()
                                            AxisValueLabel(format: .dateTime.day())
                                                .font(.system(size: 9))
                                        }
                                    }
                                    .chartYAxis {
                                        AxisMarks { v in
                                            AxisGridLine()
                                            AxisValueLabel { Text(String(format: "%.0f", v.as(Double.self) ?? 0)).font(.system(size: 9)) }
                                        }
                                    }
                                }
                                .padding(16)
                            }
                            .padding(.horizontal, 16)
                        }

                        // Payment split
                        if vm.totalRevenue > 0 {
                            AKCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Ödəniş üsulları")
                                        .font(.system(size: 13, weight: .semibold)).foregroundColor(.slate700)
                                    HStack(spacing: 12) {
                                        PaymentBar(label: "💵 Nağd", value: vm.cashTotal, total: vm.totalRevenue, color: Color(hex: "#10B981"))
                                        PaymentBar(label: "💳 Kart", value: vm.cardTotal, total: vm.totalRevenue, color: .brand)
                                    }
                                }
                                .padding(16)
                            }
                            .padding(.horizontal, 16)
                        }

                        // Top products
                        if !vm.topProducts.isEmpty {
                            AKCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Ən çox satılan məhsullar")
                                        .font(.system(size: 13, weight: .semibold)).foregroundColor(.slate700)
                                    ForEach(Array(vm.topProducts.prefix(8).enumerated()), id: \.element.name) { idx, p in
                                        HStack(spacing: 8) {
                                            Text("\(idx + 1)")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.slate400)
                                                .frame(width: 18)
                                            Text(p.name)
                                                .font(.system(size: 13)).foregroundColor(.slate800)
                                                .lineLimit(1)
                                            Spacer()
                                            Text(String(format: "%.2f ₼", p.revenue))
                                                .font(.system(size: 13, weight: .semibold)).foregroundColor(.brand)
                                        }
                                        if idx < min(vm.topProducts.count, 8) - 1 { Divider() }
                                    }
                                }
                                .padding(16)
                            }
                            .padding(.horizontal, 16)
                        }

                        // Orders list
                        if !vm.orders.isEmpty {
                            VStack(spacing: 0) {
                                AKSectionHeader(title: "Sifarişlər (\(vm.orders.count))")
                                AKCard {
                                    VStack(spacing: 0) {
                                        ForEach(Array(vm.orders.prefix(20).enumerated()), id: \.element.id) { idx, order in
                                            HStack(spacing: 10) {
                                                Text(order.number)
                                                    .font(.appMono).foregroundColor(.brand)
                                                    .padding(.horizontal, 7).padding(.vertical, 3)
                                                    .background(Color.brandLight).cornerRadius(5)
                                                VStack(alignment: .leading, spacing: 1) {
                                                    Text("\(order.items.count) məhsul").font(.system(size: 12)).foregroundColor(.slate700)
                                                    Text(String(order.createdAt.prefix(10))).font(.system(size: 11)).foregroundColor(.slate400)
                                                }
                                                Spacer()
                                                Text(String(format: "%.2f ₼", order.total))
                                                    .font(.system(size: 13, weight: .bold)).foregroundColor(.slate900)
                                                Image(systemName: order.payMethod == "cash" ? "banknote" : "creditcard")
                                                    .font(.system(size: 11)).foregroundColor(.slate400)
                                            }
                                            .padding(.horizontal, 14).padding(.vertical, 10)
                                            if idx < min(vm.orders.count, 20) - 1 { Divider().padding(.leading, 14) }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        if vm.isLoading {
                            ProgressView().tint(.brand).padding()
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.vertical, 16)
                }
                .background(Color.appBg)
            }
            .background(Color.appBg)
            .navigationBarHidden(true)
            .task { await vm.load() }
        }
    }
}

struct PaymentBar: View {
    let label: String; let value: Double; let total: Double; let color: Color
    var pct: Double { total > 0 ? value / total : 0 }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 12)).foregroundColor(.slate600)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.slate100).frame(height: 8)
                    RoundedRectangle(cornerRadius: 4).fill(color).frame(width: geo.size.width * pct, height: 8)
                }
            }
            .frame(height: 8)
            HStack {
                Text(String(format: "%.2f ₼", value)).font(.system(size: 13, weight: .bold)).foregroundColor(.slate900)
                Spacer()
                Text(String(format: "%.0f%%", pct * 100)).font(.system(size: 11)).foregroundColor(.slate400)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
