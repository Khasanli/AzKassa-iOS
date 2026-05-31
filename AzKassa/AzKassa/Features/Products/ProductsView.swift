import SwiftUI

struct ProductsView: View {
    @StateObject private var vm = ProductsViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Page header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("nav_products_group › Məhsullar")
                            .font(.system(size: 11))
                            .foregroundColor(.slate400)
                        Text("Məhsullar")
                            .font(.appTitle)
                            .foregroundColor(.slate900)
                    }
                    Spacer()
                    Button {
                        vm.showAdd = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("Yeni")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.brand)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)

                Divider()

                // Search bar
                HStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundColor(.slate400).font(.system(size: 14))
                        TextField("Ad, SKU və ya barkod...", text: $vm.search)
                            .font(.appBody)
                            .autocapitalization(.none)
                        if !vm.search.isEmpty {
                            Button { vm.search = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.slate300)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.slate200, lineWidth: 1))
                }
                .padding(12)
                .background(Color.appBg)

                // Product list
                if vm.isLoading && vm.products.isEmpty {
                    Spacer()
                    ProgressView().tint(Color.brand)
                    Spacer()
                } else {
                    List {
                        ForEach(vm.filteredProducts) { product in
                            NavigationLink(destination: ProductDetailView(product: product, vm: vm)) {
                                ProductRow(product: product)
                            }
                            .listRowBackground(Color.white)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        }
                        .onDelete { indexSet in
                            Task {
                                for i in indexSet { await vm.delete(vm.filteredProducts[i]) }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.appBg)
                    .refreshable { await vm.load() }
                }
            }
            .background(Color.appBg)
            .navigationBarHidden(true)
            .sheet(isPresented: $vm.showAdd) { AddProductView(vm: vm) }
            .task { await vm.load() }
        }
    }
}

struct ProductRow: View {
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            // Icon box
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.slate100)
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: "shippingbox").font(.system(size: 16)).foregroundColor(.slate300))

            VStack(alignment: .leading, spacing: 3) {
                Text(product.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.slate900)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(product.sku)
                        .font(.appMono)
                        .foregroundColor(.slate400)
                    Text("·")
                        .foregroundColor(.slate300)
                    Text(product.category)
                        .font(.system(size: 11))
                        .foregroundColor(.slate500)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.slate100)
                        .cornerRadius(4)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                if product.discountPct > 0 {
                    Text(String(format: "%.2f ₼", product.effectivePrice))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.brand)
                    Text(String(format: "%.2f ₼", product.price))
                        .font(.system(size: 11))
                        .strikethrough()
                        .foregroundColor(.slate400)
                } else {
                    Text(String(format: "%.2f ₼", product.price))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.brand)
                }
                HStack(spacing: 3) {
                    if product.isLowStock {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "#F59E0B"))
                    }
                    Text("\(Int(product.stock)) \(product.unit)")
                        .font(.system(size: 11))
                        .foregroundColor(product.isLowStock ? Color(hex: "#F59E0B") : .slate500)
                }
            }
        }
        .padding(.vertical, 10)
    }
}
