import SwiftUI
import AVFoundation

struct POSView: View {
    @StateObject private var vm = POSViewModel()

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Left: product browser
                productBrowser
                    .frame(maxWidth: .infinity)

                Divider()

                // Right: cart (iPad split, iPhone sheet)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    cartPanel
                        .frame(width: 320)
                }
            }
            .navigationTitle("Satış Nöqtəsi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            vm.showCart = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "cart.fill")
                                if !vm.cart.isEmpty {
                                    Text("\(vm.cart.count)")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Color("BrandColor"))
                                        .clipShape(Circle())
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $vm.showCart) {
                CartSheet(vm: vm)
            }
            .sheet(isPresented: $vm.showScanner) {
                BarcodeScannerView { code in
                    vm.showScanner = false
                    vm.processBarcode(code)
                }
            }
            .alert("Ödəniş tamamlandı", isPresented: $vm.showPaidAlert) {
                Button("Yeni satış") { vm.resetCart() }
            } message: {
                Text(vm.paidTotal.map { "Məbləğ: \(String(format: "%.2f", $0)) ₼" } ?? "")
            }
            .task { await vm.loadProducts() }
        }
    }

    private var productBrowser: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Məhsul axtar...", text: $vm.search)
                    .autocapitalization(.none)
                if !vm.search.isEmpty {
                    Button { vm.search = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                }
                Button {
                    vm.showScanner = true
                } label: {
                    Image(systemName: "barcode.viewfinder")
                        .foregroundColor(Color("BrandColor"))
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()

            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryChip(label: "Hamısı", isSelected: vm.selectedCategory == nil) {
                        vm.selectedCategory = nil
                    }
                    ForEach(vm.categories, id: \.self) { cat in
                        CategoryChip(label: cat, isSelected: vm.selectedCategory == cat) {
                            vm.selectedCategory = cat
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 8)

            // Product grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    ForEach(vm.filteredProducts) { product in
                        ProductCard(product: product, inCart: vm.isInCart(product)) {
                            vm.addToCart(product)
                        }
                    }
                }
                .padding()
            }
        }
    }

    private var cartPanel: some View {
        CartPanelView(vm: vm)
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color("BrandColor") : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Product Card

struct ProductCard: View {
    let product: Product
    let inCart: Bool
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                        .frame(height: 60)
                        .overlay(Image(systemName: "shippingbox").foregroundColor(.secondary))
                    if inCart {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color("BrandColor"))
                            .padding(4)
                    }
                }
                Text(product.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)
                    .foregroundColor(.primary)

                HStack {
                    if product.discountPct > 0 {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(String(format: "%.2f ₼", product.effectivePrice))
                                .font(.caption.bold())
                                .foregroundColor(Color("BrandColor"))
                            Text(String(format: "%.2f ₼", product.price))
                                .font(.caption2)
                                .strikethrough()
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text(String(format: "%.2f ₼", product.price))
                            .font(.caption.bold())
                            .foregroundColor(Color("BrandColor"))
                    }
                    Spacer()
                    Text("\(Int(product.stock))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(10)
            .background(inCart ? Color("BrandColor").opacity(0.08) : Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(inCart ? Color("BrandColor") : Color(.systemGray5), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .disabled(product.stock <= 0)
    }
}
