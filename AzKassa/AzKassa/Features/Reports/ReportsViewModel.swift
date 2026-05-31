import Foundation

enum DateRange: String, CaseIterable, Identifiable {
    case today, yesterday, week, month, lastMonth, all
    var id: String { rawValue }
    var label: String {
        switch self {
        case .today:     return "Bu gün"
        case .yesterday: return "Dünən"
        case .week:      return "7 gün"
        case .month:     return "Bu ay"
        case .lastMonth: return "Keçən ay"
        case .all:       return "Hamısı"
        }
    }
    var startDate: Date? {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .today:     return cal.startOfDay(for: now)
        case .yesterday: return cal.startOfDay(for: cal.date(byAdding: .day, value: -1, to: now)!)
        case .week:      return cal.date(byAdding: .day, value: -7, to: now)
        case .month:     return cal.date(from: cal.dateComponents([.year, .month], from: now))
        case .lastMonth:
            let thisMonth = cal.date(from: cal.dateComponents([.year, .month], from: now))!
            return cal.date(byAdding: .month, value: -1, to: thisMonth)
        case .all:       return nil
        }
    }
    var endDate: Date? {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .yesterday:
            let start = cal.startOfDay(for: cal.date(byAdding: .day, value: -1, to: now)!)
            return cal.date(byAdding: .day, value: 1, to: start)
        case .lastMonth:
            return cal.date(from: cal.dateComponents([.year, .month], from: now))
        default: return nil
        }
    }
}

struct SalesByDay: Identifiable {
    let id = UUID()
    let date: Date
    let total: Double
}

struct TopProduct {
    let name: String
    let revenue: Double
}

@MainActor
final class ReportsViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var isLoading = false
    @Published var dateRange: DateRange = .week

    var filteredOrders: [Order] {
        let fmt = ISO8601DateFormatter()
        return orders.filter { order in
            guard let date = fmt.date(from: order.createdAt) else { return true }
            if let start = dateRange.startDate, date < start { return false }
            if let end = dateRange.endDate, date >= end { return false }
            return true
        }
    }

    var totalRevenue: Double { filteredOrders.reduce(0) { $0 + $1.total } }
    var avgOrder: Double { filteredOrders.isEmpty ? 0 : totalRevenue / Double(filteredOrders.count) }
    var cashTotal: Double { filteredOrders.filter { $0.payMethod == "cash" }.reduce(0) { $0 + $1.total } }
    var cardTotal: Double { filteredOrders.filter { $0.payMethod == "card" }.reduce(0) { $0 + $1.total } }

    var salesByDay: [SalesByDay] {
        let fmt = ISO8601DateFormatter()
        let cal = Calendar.current
        var dayMap: [Date: Double] = [:]
        for order in filteredOrders {
            guard let date = fmt.date(from: order.createdAt) else { continue }
            let day = cal.startOfDay(for: date)
            dayMap[day, default: 0] += order.total
        }
        return dayMap.map { SalesByDay(date: $0.key, total: $0.value) }
            .sorted { $0.date < $1.date }
    }

    var topProducts: [TopProduct] {
        var map: [String: Double] = [:]
        for order in filteredOrders {
            for item in order.items { map[item.name, default: 0] += item.price }
        }
        return map.map { TopProduct(name: $0.key, revenue: $0.value) }
            .sorted { $0.revenue > $1.revenue }
    }

    func load() async {
        isLoading = true
        orders = (try? await APIService.shared.fetchOrders(limit: 500)) ?? []
        isLoading = false
    }
}
