import SwiftUI

struct AddProductView: View {
    @ObservedObject var vm: ProductsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var sku = ""
    @State private var barcode = ""
    @State private var category = "Digər"
    @State private var price = ""
    @State private var costPrice = ""
    @State private var unit = "ədəd"
    @State private var stock = ""
    @State private var minStock = "10"
    @State private var discountPct = ""
    @State private var isCritical = false
    @State private var showScanner = false

    let categories = ["Ərzaq", "Kimyəvi", "Tekstil", "Ev Malları", "Tikinti", "Digər",
                      "Süd Məhsulları", "Ət Məhsulları", "Meyvə-Tərəvəz", "Çay", "Qəhvə", "Şirniyyat", "Çörək", "İçki"]
    let units = ["ədəd", "kq", "q", "litr", "ml", "paket", "dəst", "m", "m²"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Əsas") {
                    TextField("Məhsul adı *", text: $name)
                    TextField("SKU *", text: $sku)
                    HStack {
                        TextField("Barkod", text: $barcode)
                        Button {
                            showScanner = true
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                                .foregroundColor(Color("BrandColor"))
                        }
                    }
                    Picker("Kateqoriya", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    Picker("Ölçü vahidi", selection: $unit) {
                        ForEach(units, id: \.self) { Text($0) }
                    }
                }

                Section("Qiymət") {
                    TextField("Alış qiyməti (₼)", text: $costPrice)
                        .keyboardType(.decimalPad)
                    TextField("Satış qiyməti (₼) *", text: $price)
                        .keyboardType(.decimalPad)
                    TextField("Endirim %", text: $discountPct)
                        .keyboardType(.decimalPad)
                }

                Section("Stok") {
                    TextField("Başlanğıc stok", text: $stock)
                        .keyboardType(.decimalPad)
                    TextField("Minimum stok", text: $minStock)
                        .keyboardType(.decimalPad)
                    Toggle("Kritik xəbərdarlıq", isOn: $isCritical)
                }
            }
            .navigationTitle("Yeni Məhsul")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Ləğv et") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Saxla") { save() }
                        .disabled(name.isEmpty || sku.isEmpty || price.isEmpty)
                }
            }
            .sheet(isPresented: $showScanner) {
                BarcodeScannerView { code in
                    barcode = code
                    showScanner = false
                }
            }
        }
    }

    private func save() {
        let measuredUnits = Set(["kq", "kg", "q", "litr", "ml"])
        let input = ProductInput(
            name: name, sku: sku, barcode: barcode.isEmpty ? String(Int.random(in: 1000000000000...9999999999999)) : barcode,
            category: category, productType: nil,
            price: Double(price) ?? 0,
            costPrice: Double(costPrice) ?? 0,
            unit: unit,
            priceUnit: measuredUnits.contains(unit) ? "kg" : "piece",
            stock: Double(stock) ?? 0,
            minStock: Double(minStock) ?? 10,
            isCritical: isCritical,
            discountPct: Double(discountPct) ?? 0
        )
        Task { await vm.create(input) }
    }
}
