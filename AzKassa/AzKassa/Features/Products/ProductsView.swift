import SwiftUI

struct ProductsView: View {
    @StateObject private var vm = ProductsViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.filteredProducts) { product in
                    NavigationLink(destination: ProductDetailView(product: product, vm: vm)) {
                        ProductRow(product: product)
                    }
                }
                .onDelete { indexSet in
                    Task {
                        for i in indexSet {
                            await vm.delete(vm.filteredProducts[i])
                        }
                    }
                }
            }
            .searchable(text: $vm.search, prompt: "Məhsul axtar")
            .navigationTitle("Məhsullar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { vm.showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable { await vm.load() }
            .sheet(isPresented: $vm.showAdd) {
                AddProductView(vm: vm)
            }
            .task { await vm.load() }
        }
    }
}

struct ProductRow: View {
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: "shippingbox").foregroundColor(.secondary))

            VStack(alignment: .leading, spacing: 2) {
                Text(product.name).font(.subheadline.weight(.semibold))
                HStack {
                    Text(product.sku).font(.caption).foregroundColor(.secondary)
                    Text("·").foregroundColor(.secondary)
                    Text(product.category).font(.caption).foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if product.discountPct > 0 {
                    Text(String(format: "%.2f ₼", product.effectivePrice))
                        .font(.subheadline.bold()).foregroundColor(Color("BrandColor"))
                    Text(String(format: "%.2f ₼", product.price))
                        .font(.caption2).strikethrough().foregroundColor(.secondary)
                } else {
                    Text(String(format: "%.2f ₼", product.price))
                        .font(.subheadline.bold()).foregroundColor(Color("BrandColor"))
                }
                Text("\(Int(product.stock)) \(product.unit)")
                    .font(.caption)
                    .foregroundColor(product.isLowStock ? .red : .secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
