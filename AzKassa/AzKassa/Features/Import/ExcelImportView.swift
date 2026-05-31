import SwiftUI
import UniformTypeIdentifiers

// MARK: - CSV/Excel Import (matches web ExcelImportModal)

struct ImportRow: Identifiable {
    let id = UUID()
    var name: String
    var barcode: String
    var price: Double
    var costPrice: Double
    var category: String
    var unit: String
    var isValid: Bool
    var error: String?
}

struct ExcelImportView: View {
    let onImport: ([ImportRow]) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var stage: Stage = .pick
    @State private var rows: [ImportRow] = []
    @State private var selected: Set<UUID> = []
    @State private var fileName = ""
    @State private var showPicker = false
    @State private var parseError: String?

    enum Stage { case pick, preview, done }

    var validRows: [ImportRow] { rows.filter { $0.isValid } }
    var selectedValid: [ImportRow] { validRows.filter { selected.contains($0.id) } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                switch stage {
                case .pick:   pickView
                case .preview: previewView
                case .done:   doneView
                }
            }
            .navigationTitle("Excel / CSV İdxalı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Ləğv et") { dismiss() }
                }
                if stage == .preview {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("İdxal et (\(selectedValid.count))") {
                            onImport(selectedValid)
                            stage = .done
                        }
                        .disabled(selectedValid.isEmpty)
                        .foregroundColor(.brand)
                    }
                }
            }
        }
    }

    // MARK: - Pick stage

    private var pickView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Drop zone
            Button { showPicker = true } label: {
                VStack(spacing: 16) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 48)).foregroundColor(.brand)
                    Text("CSV faylı seçin")
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.slate900)
                    Text("Klikləyin · .csv, .txt")
                        .font(.system(size: 13)).foregroundColor(.slate400)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(Color.brandLight)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.brand.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6])))
            }
            .padding(.horizontal, 24)

            // Expected columns
            VStack(alignment: .leading, spacing: 8) {
                Text("Gözlənilən sütunlar:")
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(.slate500)
                HStack(spacing: 6) {
                    ForEach(["Ad *", "Satış qiyməti *", "Alış qiyməti", "Barkod", "Kateqoriya", "Ölçü vahidi"], id: \.self) { col in
                        Text(col)
                            .font(.system(size: 11, design: .monospaced))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(col.contains("*") ? Color.brandLight : Color.slate100)
                            .foregroundColor(col.contains("*") ? Color.brand : Color.slate600)
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.horizontal, 24)

            if let err = parseError {
                Text(err).font(.system(size: 13)).foregroundColor(.red).padding(.horizontal, 24)
            }

            Spacer()
        }
        .background(Color.appBg)
        .fileImporter(isPresented: $showPicker, allowedContentTypes: [.data]) { result in
            switch result {
            case .success(let url):
                fileName = url.lastPathComponent
                parseCSV(url: url)
            case .failure(let e):
                parseError = e.localizedDescription
            }
        }
    }

    // MARK: - Preview stage

    private var previewView: some View {
        VStack(spacing: 0) {
            // Summary bar
            HStack {
                Image(systemName: "doc.text").foregroundColor(Color(hex: "#10B981")).font(.system(size: 13))
                Text(fileName).font(.system(size: 13, weight: .medium)).lineLimit(1)
                Text("·").foregroundColor(.slate300)
                Text("\(rows.count) sətir").font(.system(size: 12)).foregroundColor(.slate400)
                Text("(\(validRows.count) etibarlı)").font(.system(size: 12)).foregroundColor(Color(hex: "#10B981"))
                Spacer()
                Button(selected.count == validRows.count ? "Seçimi sil" : "Hamısını seç") {
                    if selected.count == validRows.count {
                        selected = []
                    } else {
                        selected = Set(validRows.map { $0.id })
                    }
                }
                .font(.system(size: 12)).foregroundColor(.brand)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color.white)

            Divider()

            List {
                ForEach(rows) { row in
                    ImportRowCell(
                        row: row,
                        isSelected: selected.contains(row.id),
                        onToggle: {
                            if row.isValid {
                                if selected.contains(row.id) { selected.remove(row.id) }
                                else { selected.insert(row.id) }
                            }
                        }
                    )
                    .listRowBackground(selected.contains(row.id) ? Color(hex: "#ECFDF5") : (row.isValid ? Color.white : Color(hex: "#FEF2F2")))
                    .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                }
            }
            .listStyle(.plain)
        }
    }

    private var doneView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64)).foregroundColor(Color(hex: "#10B981"))
            Text("\(selectedValid.count) məhsul idxal edildi")
                .font(.system(size: 18, weight: .bold)).foregroundColor(.slate900)
            Text("Məhsullar siyahıya əlavə olundu")
                .font(.appBody).foregroundColor(.slate400)
            Button("Bağla") { dismiss() }
                .foregroundColor(.brand)
            Spacer()
        }
    }

    // MARK: - CSV Parser

    private func parseCSV(url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            parseError = "Fayl oxunmadı"
            return
        }
        let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else { parseError = "Fayl boşdur"; return }

        let headers = parseCSVLine(lines[0]).map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        func col(_ aliases: [String]) -> Int? {
            aliases.compactMap { alias in headers.firstIndex(of: alias) }.first
        }

        let nameIdx     = col(["ad", "name", "məhsul adı", "məhsul"])
        let priceIdx    = col(["satış qiyməti", "satış", "sale price", "qiymət"])
        let costIdx     = col(["alış qiyməti", "alış", "cost price", "cost"])
        let barcodeIdx  = col(["barkod", "barcode", "ean", "kod"])
        let catIdx      = col(["kateqoriya", "category"])
        let unitIdx     = col(["ölçü vahidi", "vahid", "unit"])

        guard nameIdx != nil && priceIdx != nil else {
            parseError = "\"Ad\" və \"Satış qiyməti\" sütunları tapılmadı"
            return
        }

        rows = lines.dropFirst().compactMap { line in
            let cols = parseCSVLine(line)
            guard cols.count > 0 else { return nil }
            func get(_ idx: Int?) -> String { idx.flatMap { $0 < cols.count ? cols[$0] : nil } ?? "" }
            let name  = get(nameIdx)
            let price = Double(get(priceIdx).replacingOccurrences(of: ",", with: ".")) ?? 0
            let isValid = !name.trimmingCharacters(in: .whitespaces).isEmpty && price > 0
            return ImportRow(
                name: name,
                barcode: get(barcodeIdx),
                price: price,
                costPrice: Double(get(costIdx).replacingOccurrences(of: ",", with: ".")) ?? 0,
                category: get(catIdx).isEmpty ? "Digər" : get(catIdx),
                unit: get(unitIdx).isEmpty ? "ədəd" : get(unitIdx),
                isValid: isValid,
                error: isValid ? nil : (name.isEmpty ? "Ad yoxdur" : "Qiymət yanlış")
            )
        }

        selected = Set(rows.filter { $0.isValid }.map { $0.id })
        parseError = nil
        stage = .preview
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        for ch in line {
            if ch == "\"" { inQuotes.toggle() }
            else if ch == "," && !inQuotes { result.append(current.trimmingCharacters(in: .init(charactersIn: "\""))); current = "" }
            else { current.append(ch) }
        }
        result.append(current.trimmingCharacters(in: .init(charactersIn: "\"")))
        return result
    }
}

struct ImportRowCell: View {
    let row: ImportRow
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.square.fill" : (row.isValid ? "square" : "xmark.circle.fill"))
                    .foregroundColor(isSelected ? Color(hex: "#10B981") : (row.isValid ? .slate300 : .red))
                    .font(.system(size: 18))
            }
            .disabled(!row.isValid)

            VStack(alignment: .leading, spacing: 2) {
                Text(row.name.isEmpty ? "(adsız)" : row.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(row.isValid ? .slate900 : .red)
                HStack(spacing: 4) {
                    Text(row.category).font(.system(size: 11)).foregroundColor(.slate400)
                    Text("·").foregroundColor(.slate300)
                    Text(row.unit).font(.system(size: 11)).foregroundColor(.slate400)
                    if let err = row.error {
                        Text("·").foregroundColor(.slate300)
                        Text(err).font(.system(size: 11)).foregroundColor(.red)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f ₼", row.price))
                    .font(.system(size: 13, weight: .bold)).foregroundColor(.slate900)
                if row.costPrice > 0 {
                    Text(String(format: "%.2f ₼", row.costPrice))
                        .font(.system(size: 11)).foregroundColor(.slate400)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
