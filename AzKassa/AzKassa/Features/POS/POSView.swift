import SwiftUI

struct POSView: View {
    @StateObject private var vm = POSViewModel()

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                productBrowser
                    .frame(maxWidth: .infinity)

                if UIDevice.current.userInterfaceIdiom == .pad {
                    Rectangle()
                        .fill(Color.slate200)
                        .frame(width: 1)
                    CartPanelView(vm: vm)
                        .frame(width: 320)
                        .background(Color.white)
                }
            }
            .background(Color.appBg)
            .navigationBarHidden(true)
            .sheet(isPresented: $vm.showCart) { CartSheet(vm: vm) }
            .sheet(isPresented: $vm.showScanner) {
                BarcodeScannerView { code in
                    vm.showScanner = false
                    vm.processBarcode(code)
                }
            }
            .alert("Ödəniş tamamlandı", isPresented: $vm.showPaidAlert) {
                Button("Yeni satış", role: .cancel) { vm.resetCart() }
            } message: {
                Text(vm.paidTotal.map { String(format: "Məbləğ: %.2f ₼", $0) } ?? "")
            }
            .task { await vm.loadProducts() }
        }
    }

    private var productBrowser: some View {
        VStack(spacing: 0) {
            // Page header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Satış › POS")
                        .font(.system(size: 11))
                        .foregroundColor(.slate400)
                    Text("Satış Nöqtəsi")
                        .font(.appTitle)
                        .foregroundColor(.slate900)
                }
                Spacer()
                if UIDevice.current.userInterfaceIdiom == .phone {
                    Button { vm.showCart = true } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "cart.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.brand)
                            if !vm.cart.isEmpty {
                                Text("\(vm.cart.count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(3)
                                    .background(Color.brand)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)

            Divider()

            // Search + Scanner row
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(.slate400).font(.system(size: 14))
                    TextField("Məhsul axtar...", text: $vm.search)
                        .font(.appBody)
                        .autocapitalization(.none)
                    if !vm.search.isEmpty {
                        Button { vm.search = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.slate300)
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 9)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.slate200, lineWidth: 1))

                Button { vm.showScanner = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "barcode.viewfinder")
                        Text("Kamera").font(.system(size: 13, weight: .medium))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(Color.white)
                    .foregroundColor(.slate600)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.slate200, lineWidth: 1))
                }
            }
            .padding(12)
            .background(Color.appBg)

            // Category chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    POSCategoryChip(label: "Hamısı", isSelected: vm.selectedCategory == nil) {
                        vm.selectedCategory = nil
                    }
                    ForEach(vm.categories, id: \.self) { cat in
                        POSCategoryChip(label: cat, isSelected: vm.selectedCategory == cat) {
                            vm.selectedCategory = cat
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }

            // Scan message
            if let msg = vm.scanMessage {
                HStack(spacing: 8) {
                    Image(systemName: msg.hasPrefix("✓") ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(msg.hasPrefix("✓") ? Color(hex: "#10B981") : Color(hex: "#EF4444"))
                    Text(msg)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(msg.hasPrefix("✓") ? Color(hex: "#065F46") : Color(hex: "#7F1D1D"))
                    Spacer()
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(msg.hasPrefix("✓") ? Color(hex: "#ECFDF5") : Color(hex: "#FEF2F2"))
            }

            // Product grid
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 10)],
                    spacing: 10
                ) {
                    ForEach(vm.filteredProducts) { product in
                        POSProductCard(
                            product: product,
                            inCart: vm.isInCart(product)
                        ) { vm.addToCart(product) }
                    }
                }
                .padding(12)
            }
        }
    }
}

// MARK: - Category Chip

struct POSCategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(isSelected ? Color.brand : Color.white)
                .foregroundColor(isSelected ? .white : .slate600)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? Color.brand : Color.slate200, lineWidth: 1))
        }
    }
}

// MARK: - Product Card

struct POSProductCard: View {
    let product: Product
    let inCart: Bool
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(product.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(inCart ? Color.brand : .slate900)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if inCart {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.brand)
                    }
                }

                Spacer(minLength: 0)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(String(format: "%.2f ₼", product.effectivePrice))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.brand)
                        if product.discountPct > 0 {
                            Text(String(format: "%.2f ₼", product.price))
                                .font(.system(size: 10))
                                .strikethrough()
                                .foregroundColor(.slate400)
                        }
                    }
                    Spacer()
                    Text(product.stock <= 0 ? "Bitib" : "\(Int(product.stock))")
                        .font(.system(size: 10))
                        .foregroundColor(product.stock <= 0 ? Color(hex: "#EF4444") : .slate400)
                }
            }
            .padding(10)
            .frame(minHeight: 90)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(inCart ? Color(hex: "#EEF2FF") : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(inCart ? Color.brand : Color.slate200, lineWidth: inCart ? 2 : 1)
                    )
            )
        }
        .opacity(product.stock <= 0 ? 0.6 : 1)
    }
}
