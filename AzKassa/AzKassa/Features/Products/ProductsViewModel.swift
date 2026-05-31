import Foundation

@MainActor
final class ProductsViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var search = ""
    @Published var showAdd = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    var filteredProducts: [Product] {
        guard !search.isEmpty else { return products }
        return products.filter {
            $0.name.localizedCaseInsensitiveContains(search) ||
            $0.sku.localizedCaseInsensitiveContains(search) ||
            $0.barcode.contains(search)
        }
    }

    func load() async {
        isLoading = true
        do { products = try await APIService.shared.fetchProducts() }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func create(_ input: ProductInput) async {
        do {
            let p = try await APIService.shared.createProduct(input)
            products.insert(p, at: 0)
            showAdd = false
        } catch { errorMessage = error.localizedDescription }
    }

    func update(id: String, input: ProductInput) async {
        do {
            let p = try await APIService.shared.updateProduct(id: id, input: input)
            if let idx = products.firstIndex(where: { $0.id == id }) {
                products[idx] = p
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func delete(_ product: Product) async {
        do {
            try await APIService.shared.deleteProduct(id: product.id)
            products.removeAll { $0.id == product.id }
        } catch { errorMessage = error.localizedDescription }
    }
}
