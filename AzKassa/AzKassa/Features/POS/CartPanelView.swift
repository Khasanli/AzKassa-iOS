import SwiftUI

struct CartPanelView: View {
    @ObservedObject var vm: POSViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "cart.fill").foregroundColor(.slate500).font(.system(size: 15))
                Text("Səbət").font(.system(size: 14, weight: .semibold)).foregroundColor(.slate800)
                if !vm.cart.isEmpty {
                    Text("\(vm.cart.count)")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(Color.brand)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Spacer()
                if !vm.cart.isEmpty {
                    Button {
                        vm.resetCart()
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.counterclockwise").font(.system(size: 10))
                            Text("Sıfırla").font(.system(size: 12))
                        }
                        .foregroundColor(.slate400)
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)

            Divider()

            // Items
            if vm.cart.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "cart").font(.system(size: 36)).foregroundColor(.slate200)
                    Text("Səbət boşdur").font(.appBody).foregroundColor(.slate400)
                    Text("Məhsul seçin").font(.system(size: 12)).foregroundColor(.slate300)
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
                            Divider().padding(.leading, 14)
                        }
                    }
                }
            }

            Divider()

            // Footer
            VStack(spacing: 12) {
                // Discount row
                HStack(spacing: 8) {
                    Text("Endirim")
                        .font(.system(size: 13))
                        .foregroundColor(.slate500)
                    Spacer()
                    HStack(spacing: 4) {
                        DiscountTypeButton(label: "%", isSelected: vm.discountType == "pct") { vm.discountType = "pct" }
                        DiscountTypeButton(label: "₼", isSelected: vm.discountType == "fixed") { vm.discountType = "fixed" }
                    }
                    TextField("0", text: $vm.discountValue)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 13))
                        .frame(width: 52)
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .background(Color.slate100)
                        .cornerRadius(6)
                    if vm.discountAmount > 0 {
                        Text(String(format: "−%.2f ₼", vm.discountAmount))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#EF4444"))
                    }
                }

                // VAT + Total
                VStack(spacing: 4) {
                    HStack {
                        Text("ƏDV (18%)").font(.system(size: 12)).foregroundColor(.slate400)
                        Spacer()
                        Text(String(format: "%.2f ₼", vm.vatAmount)).font(.system(size: 12)).foregroundColor(.slate400)
                    }
                    if vm.discountAmount > 0 {
                        HStack {
                            Text(String(format: "%.2f ₼", vm.rawTotal)).font(.system(size: 12)).strikethrough().foregroundColor(.slate400)
                            Spacer()
                            Text(String(format: "−%.2f ₼", vm.discountAmount)).font(.system(size: 12, weight: .semibold)).foregroundColor(Color(hex: "#EF4444"))
                        }
                    }
                    HStack {
                        Text("Cəmi").font(.system(size: 14)).foregroundColor(.slate500)
                        Spacer()
                        Text(String(format: "%.2f ₼", vm.total)).font(.system(size: 22, weight: .bold)).foregroundColor(.slate900)
                    }
                }

                // Pay method
                HStack(spacing: 8) {
                    PayMethodBtn(label: "Nağd", icon: "banknote", isSelected: vm.payMethod == "cash") { vm.payMethod = "cash" }
                    PayMethodBtn(label: "Kart", icon: "creditcard", isSelected: vm.payMethod == "card") { vm.payMethod = "card" }
                }

                // Pay button
                Button {
                    Task { await vm.pay() }
                } label: {
                    Group {
                        if vm.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(vm.cart.isEmpty ? "Ödə" : String(format: "Ödə — %.2f ₼", vm.total))
                                .font(.system(size: 15, weight: .bold))
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(vm.cart.isEmpty ? Color.slate300 : Color.brand)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(vm.cart.isEmpty || vm.isLoading)
            }
            .padding(14)
            .background(Color.white)
        }
    }
}

struct CartItemRow: View {
    let item: CartItem
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.slate900).lineLimit(1)
                Text(String(format: "%.2f ₼", item.price)).font(.system(size: 11)).foregroundColor(.slate400)
            }
            Spacer()
            HStack(spacing: 6) {
                Button(action: onDecrement) {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 26, height: 26)
                        .background(Color.slate100)
                        .cornerRadius(6)
                        .foregroundColor(.slate600)
                }
                Text("\(Int(item.qty))").font(.system(size: 13, weight: .bold)).frame(minWidth: 20).foregroundColor(.slate900)
                Button(action: onIncrement) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 26, height: 26)
                        .background(Color.slate100)
                        .cornerRadius(6)
                        .foregroundColor(.slate600)
                }
            }
            Text(String(format: "%.2f ₼", item.lineTotal))
                .font(.system(size: 13, weight: .bold)).foregroundColor(.slate900).frame(width: 62, alignment: .trailing)
            Button(action: onRemove) {
                Image(systemName: "trash").font(.system(size: 12)).foregroundColor(Color(hex: "#EF4444"))
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }
}

struct DiscountTypeButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(isSelected ? Color(hex: "#FEE2E2") : Color.slate100)
                .foregroundColor(isSelected ? Color(hex: "#DC2626") : .slate500)
                .cornerRadius(6)
        }
    }
}

struct PayMethodBtn: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13))
                Text(label).font(.system(size: 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity).frame(height: 40)
            .background(isSelected ? Color.brand : Color.slate100)
            .foregroundColor(isSelected ? .white : .slate600)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.brand : Color.slate200, lineWidth: 1))
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
                            .foregroundColor(.brand)
                    }
                }
        }
    }
}
