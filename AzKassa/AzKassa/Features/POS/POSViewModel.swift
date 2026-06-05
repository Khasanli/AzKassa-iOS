import Foundation
import Combine
import AVFoundation

@MainActor
final class POSViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var cart: [CartItem] = []
    @Published var search = ""
    @Published var selectedCategory: String? = nil
    @Published var payMethod = "cash"
    @Published var discountType = "pct"
    @Published var discountValue = ""
    @Published var showCart = false
    @Published var showScanner = false
    @Published var showPaidAlert = false
    @Published var paidTotal: Double? = nil
    @Published var isLoading = false
    @Published var scanMessage: String? = nil
    @Published var scannerConnected = false

    // Scanner speed detection — Sunlux HID sends chars < 30ms apart
    private(set) var barcodeBuffer = ""
    private var lastCharTime: Date = .distantPast
    private var fastCharCount = 0
    private var scannerResetTask: Task<Void, Never>?

    private var player: AVAudioPlayer?

    var categories: [String] {
        Array(Set(products.map { $0.category })).sorted()
    }

    var filteredProducts: [Product] {
        products.filter { p in
            let matchCat = selectedCategory == nil || p.category == selectedCategory
            let matchSearch = search.isEmpty ||
                p.name.localizedCaseInsensitiveContains(search) ||
                p.sku.localizedCaseInsensitiveContains(search) ||
                p.barcode.contains(search)
            return matchCat && matchSearch
        }
    }

    var rawTotal: Double {
        cart.reduce(0) { $0 + $1.lineTotal }
    }

    var discountAmount: Double {
        let v = Double(discountValue) ?? 0
        guard v > 0 else { return 0 }
        if discountType == "pct" {
            return (rawTotal * v / 100).rounded(to: 2)
        } else {
            return min(v, rawTotal).rounded(to: 2)
        }
    }

    var total: Double { (rawTotal - discountAmount).rounded(to: 2) }
    var vatAmount: Double { (total * 18 / 118).rounded(to: 2) }

    func isInCart(_ product: Product) -> Bool {
        cart.contains { $0.productId == product.id }
    }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await APIService.shared.fetchProducts()
        } catch {}
        isLoading = false
    }

    func addToCart(_ product: Product) {
        let effectivePrice = product.effectivePrice
        if let idx = cart.firstIndex(where: { $0.productId == product.id }) {
            cart[idx].qty += 1
        } else {
            cart.append(CartItem(
                id: UUID().uuidString,
                productId: product.id,
                name: product.name,
                price: effectivePrice,
                unit: product.unit,
                qty: 1
            ))
        }
        playBeep()
    }

    func removeFromCart(id: String) {
        cart.removeAll { $0.id == id }
    }

    func setQty(id: String, qty: Double) {
        if qty <= 0 {
            removeFromCart(id: id)
        } else if let idx = cart.firstIndex(where: { $0.id == id }) {
            cart[idx].qty = qty
        }
    }

    // Called by the hidden capture TextField onChange
    func onScannerChar(_ newValue: String) {
        let now = Date()
        let gap = now.timeIntervalSince(lastCharTime) * 1000 // ms
        lastCharTime = now

        if gap < 50 && gap > 0 {
            fastCharCount += 1
            if fastCharCount >= 3 {
                scannerConnected = true
                scannerResetTask?.cancel()
                scannerResetTask = Task {
                    try? await Task.sleep(nanoseconds: 15_000_000_000) // 15s idle → disconnect
                    if !Task.isCancelled { self.scannerConnected = false; self.fastCharCount = 0 }
                }
            }
        } else {
            fastCharCount = 0
        }
        barcodeBuffer = newValue
    }

    // Called when scanner sends Enter (onSubmit)
    func commitBarcode() {
        let code = barcodeBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        barcodeBuffer = ""
        guard !code.isEmpty else { return }
        processBarcode(code)
    }

    func processBarcode(_ code: String) {
        if let product = products.first(where: {
            $0.barcode == code || $0.sku == code ||
            $0.barcode == code.trimmingCharacters(in: .whitespaces)
        }) {
            addToCart(product)
            scanMessage = "✓ \(product.name)"
        } else {
            scanMessage = "✗ \"\(code)\" tapılmadı"
            playBeep(type: "err")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.scanMessage = nil }
    }

    func pay() async {
        guard !cart.isEmpty else { return }
        isLoading = true
        let request = CreateOrderRequest(
            items: cart.map { item in
                CreateOrderRequest.Item(
                    productId: item.productId,
                    name: item.name,
                    price: item.lineTotal,
                    qty: item.qty,
                    unit: item.unit,
                    weightKg: item.weightKg
                )
            },
            payMethod: payMethod
        )
        do {
            _ = try await APIService.shared.createOrder(request)
            paidTotal = total
            showPaidAlert = true
            await loadProducts()
        } catch {}
        isLoading = false
    }

    func resetCart() {
        cart = []
        discountValue = ""
        paidTotal = nil
        showCart = false
    }

    private func playBeep(type: String = "ok") {
        guard let url = Bundle.main.url(forResource: "scanner-beep", withExtension: "mp3") else { return }
        try? player = AVAudioPlayer(contentsOf: url)
        player?.volume = type == "ok" ? 1.0 : 0.5
        if type == "err" { player?.enableRate = true; player?.rate = 0.5 }
        player?.play()
    }
}

extension Double {
    func rounded(to places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }
}
