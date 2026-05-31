import Foundation

// MARK: - Auth

struct AuthUser: Codable {
    let id: String
    let email: String
    let fullName: String
    let companyName: String
    let profile: String
    let currency: String?
}

struct StaffUser: Codable {
    let id: String
    let username: String
    let fullName: String
    let permissions: [String]
}

struct LoginResponse: Codable {
    let token: String
    let user: AuthUser?
    let staff: StaffUser?
}

// MARK: - Product

struct Product: Codable, Identifiable {
    let id: String
    var name: String
    var sku: String
    var barcode: String
    var category: String
    var productType: String?
    var price: Double
    var costPrice: Double
    var unit: String
    var priceUnit: String
    var stock: Double
    var minStock: Double
    var isCritical: Bool
    var discountPct: Double
    let businessId: String
    let createdAt: String
    let updatedAt: String

    var effectivePrice: Double {
        discountPct > 0 ? price * (1 - discountPct / 100) : price
    }

    var isLowStock: Bool {
        isCritical && stock <= minStock
    }
}

struct ProductInput: Codable {
    var name: String
    var sku: String
    var barcode: String
    var category: String
    var productType: String?
    var price: Double
    var costPrice: Double
    var unit: String
    var priceUnit: String
    var stock: Double
    var minStock: Double
    var isCritical: Bool
    var discountPct: Double
}

// MARK: - Order

struct Order: Codable, Identifiable {
    let id: String
    let number: String
    let total: Double
    let payMethod: String
    let businessId: String
    let createdAt: String
    let items: [OrderItem]
}

struct OrderItem: Codable, Identifiable {
    let id: String
    let name: String
    let price: Double
    let qty: Double
    let unit: String
    let weightKg: Double?
    let productId: String?
}

struct CreateOrderRequest: Codable {
    struct Item: Codable {
        let productId: String?
        let name: String
        let price: Double
        let qty: Double
        let unit: String
        let weightKg: Double?
    }
    let items: [Item]
    let payMethod: String
}

// MARK: - Cart

struct CartItem: Identifiable {
    let id: String
    let productId: String?
    var name: String
    var price: Double
    var unit: String
    var qty: Double
    var weightKg: Double?
    var pricePerKg: Double?

    var lineTotal: Double {
        weightKg != nil ? price : price * qty
    }
}
