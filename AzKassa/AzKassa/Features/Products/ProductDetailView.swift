import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @ObservedObject var vm: ProductsViewModel
    @State private var input: ProductInput
    @State private var isEditing = false
    @Environment(\.dismiss) var dismiss

    init(product: Product, vm: ProductsViewModel) {
        self.product = product
        self.vm = vm
        _input = State(initialValue: ProductInput(
            name: product.name, sku: product.sku, barcode: product.barcode,
            category: product.category, productType: product.productType,
            price: product.price, costPrice: product.costPrice,
            unit: product.unit, priceUnit: product.priceUnit,
            stock: product.stock, minStock: product.minStock,
            isCritical: product.isCritical, discountPct: product.discountPct
        ))
    }

    var body: some View {
        Form {
            Section("Məhsul məlumatları") {
                LabeledContent("Ad") {
                    if isEditing {
                        TextField("Ad", text: $input.name)
                            .multilineTextAlignment(.trailing)
                    } else { Text(product.name) }
                }
                LabeledContent("SKU") {
                    if isEditing {
                        TextField("SKU", text: $input.sku)
                            .multilineTextAlignment(.trailing)
                    } else { Text(product.sku) }
                }
                LabeledContent("Barkod") {
                    if isEditing {
                        TextField("Barkod", text: $input.barcode)
                            .multilineTextAlignment(.trailing)
                    } else { Text(product.barcode) }
                }
            }

            Section("Qiymət") {
                LabeledContent("Satış qiyməti (₼)") {
                    if isEditing {
                        TextField("0.00", value: $input.price, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    } else { Text(String(format: "%.2f ₼", product.price)) }
                }
                LabeledContent("Alış qiyməti (₼)") {
                    if isEditing {
                        TextField("0.00", value: $input.costPrice, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    } else { Text(String(format: "%.2f ₼", product.costPrice)) }
                }
                LabeledContent("Endirim %") {
                    if isEditing {
                        TextField("0", value: $input.discountPct, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    } else {
                        Text(product.discountPct > 0 ? "\(Int(product.discountPct))%" : "—")
                            .foregroundColor(product.discountPct > 0 ? .red : .secondary)
                    }
                }
                if product.discountPct > 0 {
                    LabeledContent("Effektiv qiymət") {
                        Text(String(format: "%.2f ₼", product.effectivePrice))
                            .foregroundColor(Color("BrandColor")).bold()
                    }
                }
            }

            Section("Stok") {
                LabeledContent("Stok") {
                    if isEditing {
                        TextField("0", value: $input.stock, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    } else {
                        Text("\(Int(product.stock)) \(product.unit)")
                            .foregroundColor(product.isLowStock ? .red : .primary)
                    }
                }
                LabeledContent("Min stok") {
                    if isEditing {
                        TextField("10", value: $input.minStock, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    } else { Text(String(Int(product.minStock))) }
                }
                LabeledContent("Kritik xəbərdarlıq") {
                    if isEditing {
                        Toggle("", isOn: $input.isCritical)
                    } else {
                        Text(product.isCritical ? "Aktiv" : "Deaktiv")
                            .foregroundColor(product.isCritical ? .orange : .secondary)
                    }
                }
            }
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Saxla" : "Düzəliş") {
                    if isEditing {
                        Task { await vm.update(id: product.id, input: input) }
                    }
                    isEditing.toggle()
                }
            }
        }
    }
}
