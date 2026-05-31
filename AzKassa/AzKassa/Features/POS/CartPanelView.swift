import SwiftUI

struct CartPanelView: View {
    @ObservedObject var vm: POSViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "cart.fill").foregroundColor(.secondary)
                Text("Səbət").font(.headline)
                if !vm.cart.isEmpty {
                    Text("\(vm.cart.count)")
                        .font(.caption.bold())
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color("BrandColor"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Spacer()
                if !vm.cart.isEmpty {
                    Button("Sıfırla") { vm.resetCart() }
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color(.systemBackground))

            Divider()

            // Cart items
            if vm.cart.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "cart").font(.system(size: 40)).foregroundColor(.secondary)
                    Text("Səbət boşdur").foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(vm.cart) { item in
                            CartItemRow(item: item,
                                onIncrement: { vm.setQty(id: item.id, qty: item.qty + 1) },
                                onDecrement: { vm.setQty(id: item.id, qty: item.qty - 1) },
                                onRemove: { vm.removeFromCart(id: item.id) }
                            )
                            Divider().padding(.leading)
                        }
                    }
                }
            }

            Divider()

            // Footer: discount + total + pay
            VStack(spacing: 12) {
                // Discount row
                HStack(spacing: 8) {
                    Text("Endirim").font(.subheadline).foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Button("%") { vm.discountType = "pct" }
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(vm.discountType == "pct" ? Color.red.opacity(0.15) : Color(.systemGray6))
                            .foregroundColor(vm.discountType == "pct" ? .red : .primary)
                            .cornerRadius(6)
                            .font(.caption.bold())
                        Button("₼") { vm.discountType = "fixed" }
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(vm.discountType == "fixed" ? Color.red.opacity(0.15) : Color(.systemGray6))
                            .foregroundColor(vm.discountType == "fixed" ? .red : .primary)
                            .cornerRadius(6)
                            .font(.caption.bold())
                    }
                    TextField("0", text: $vm.discountValue)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        .padding(6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .font(.subheadline)
                    if vm.discountAmount > 0 {
                        Text("−\(String(format: "%.2f", vm.discountAmount)) ₼")
                            .font(.caption.bold()).foregroundColor(.red)
                    }
                }

                // Total
                HStack {
                    Text("Cəmi").font(.subheadline).foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.2f ₼", vm.total))
                        .font(.title2.bold())
                }

                // Pay method
                HStack(spacing: 8) {
                    PayMethodButton(label: "Nağd", icon: "banknote", isSelected: vm.payMethod == "cash") {
                        vm.payMethod = "cash"
                    }
                    PayMethodButton(label: "Kart", icon: "creditcard", isSelected: vm.payMethod == "card") {
                        vm.payMethod = "card"
                    }
                }

                // Pay button
                Button {
                    Task { await vm.pay() }
                } label: {
                    Group {
                        if vm.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(vm.cart.isEmpty ? "Ödə" : "Ödə — \(String(format: "%.2f", vm.total)) ₼")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(vm.cart.isEmpty ? Color.gray : Color("BrandColor"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(vm.cart.isEmpty || vm.isLoading)
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
}

struct CartItemRow: View {
    let item: CartItem
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                Text(String(format: "%.2f ₼", item.price)).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Button(action: onDecrement) {
                    Image(systemName: "minus").frame(width: 28, height: 28)
                        .background(Color(.systemGray6)).cornerRadius(6)
                }
                Text("\(Int(item.qty))").font(.subheadline.bold()).frame(minWidth: 24)
                Button(action: onIncrement) {
                    Image(systemName: "plus").frame(width: 28, height: 28)
                        .background(Color(.systemGray6)).cornerRadius(6)
                }
            }
            Text(String(format: "%.2f ₼", item.lineTotal))
                .font(.subheadline.bold()).frame(width: 70, alignment: .trailing)
            Button(action: onRemove) {
                Image(systemName: "trash").foregroundColor(.red)
            }
        }
        .padding(.horizontal).padding(.vertical, 10)
    }
}

struct PayMethodButton: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(label).font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(isSelected ? Color("BrandColor") : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
        }
    }
}

struct CartSheet: View {
    @ObservedObject var vm: POSViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            CartPanelView(vm: vm)
                .navigationTitle("Səbət")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Bağla") { dismiss() }
                    }
                }
        }
    }
}
