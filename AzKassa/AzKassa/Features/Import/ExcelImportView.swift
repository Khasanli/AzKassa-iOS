import SwiftUI
import UniformTypeIdentifiers

// MARK: - CSV Import — matches web ExcelImportModal with column mapping stage

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

struct FieldMapping {
    var name: String?
    var price: String?
    var costPrice: String?
    var barcode: String?
    var category: String?
    var unit: String?

    var isValid: Bool { name != nil && price != nil }
}

private let fieldDefs: [(key: WritableKeyPath<FieldMapping, String?>, label: String, required: Bool)] = [
    (\.name,      "Məhsul adı",    true),
    (\.price,     "Satış qiyməti", true),
    (\.costPrice, "Alış qiyməti",  false),
    (\.barcode,   "Barkod",        false),
    (\.category,  "Kateqoriya",    false),
    (\.unit,      "Ölçü vahidi",   false),
]

struct ExcelImportView: View {
    let onImport: ([ImportRow]) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var stage: Stage = .pick
    @State private var rows: [ImportRow] = []
    @State private var selected: Set<UUID> = []
    @State private var fileName = ""
    @State private var showPicker = false
    @State private var parseError: String?
    @State private var rawData: [[String: String]] = []
    @State private var headers: [String] = []
    @State private var mapping = FieldMapping()

    enum Stage { case pick, map, preview, done }

    var validRows: [ImportRow]    { rows.filter { $0.isValid } }
    var selectedValid: [ImportRow] { validRows.filter { selected.contains($0.id) } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                switch stage {
                case .pick:    pickView
                case .map:     mapView
                case .preview: previewView
                case .done:    doneView
                }
            }
            .navigationTitle("Excel / CSV İdxalı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(stage == .done ? "Bağla" : "Ləğv et") { dismiss() }
                }
                if stage == .map {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Davam et") { applyMapping() }
                            .disabled(!mapping.isValid)
                            .foregroundColor(mapping.isValid ? .brand : .slate300)
                    }
                }
                if stage == .preview {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("İdxal et (\(selectedValid.count))") {
                            onImport(selectedValid); stage = .done
                        }
                        .disabled(selectedValid.isEmpty).foregroundColor(.brand)
                    }
                }
            }
        }
    }

    // MARK: - Pick

    private var pickView: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#ECFDF5"))
                    .frame(width: 80, height: 80)
                    .overlay(Image(systemName: "tablecells").font(.system(size: 36)).foregroundColor(Color(hex: "#059669")))

                Text("Excel / CSV İdxalı")
                    .font(.system(size: 18, weight: .bold)).foregroundColor(.slate900)
            }

            Button { showPicker = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.badge.plus")
                    Text("Fayl seçin (.csv)")
                }
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(Color(hex: "#059669"))
                .foregroundColor(.white).cornerRadius(12)
            }
            .padding(.horizontal, 24)

            // Expected columns hint
            VStack(alignment: .leading, spacing: 8) {
                Text("Gözlənilən sütunlar:").font(.system(size: 12, weight: .semibold)).foregroundColor(.slate500)
                HStack(spacing: 6) {
                    ForEach(["Ad *", "Satış qiyməti *", "Alış qiyməti", "Barkod", "Kateqoriya"], id: \.self) { col in
                        Text(col)
                            .font(.system(size: 11, design: .monospaced))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(col.contains("*") ? Color(hex: "#ECFDF5") : Color.slate100)
                            .foregroundColor(col.contains("*") ? Color(hex: "#059669") : .slate600)
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.horizontal, 24)

            if let err = parseError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill").foregroundColor(.red)
                    Text(err).font(.system(size: 13)).foregroundColor(.red)
                }
                .padding(.horizontal, 24)
            }
            Spacer()
        }
        .background(Color.appBg)
        .fileImporter(isPresented: $showPicker, allowedContentTypes: [.data]) { result in
            switch result {
            case .success(let url): loadFile(url: url)
            case .failure(let e):  parseError = e.localizedDescription
            }
        }
    }

    // MARK: - Mapping stage (mirrors web ColumnMapping step)

    private var mapView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "doc.text").foregroundColor(Color(hex: "#059669")).font(.system(size: 13))
                Text(fileName).font(.system(size: 13, weight: .medium)).lineLimit(1)
                Text("· \(rawData.count) sətir · \(headers.count) sütun")
                    .font(.system(size: 12)).foregroundColor(.slate400)
            }
            .padding(.horizontal, 14).padding(.vertical, 10).background(Color.white)
            Divider()

            Text("Excel sütunlarını məhsul sahələrinə uyğunlaşdırın")
                .font(.system(size: 12)).foregroundColor(.slate500)
                .padding(12)

            List {
                ForEach(fieldDefs, id: \.label) { field in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(field.label).font(.system(size: 13, weight: .medium)).foregroundColor(.slate800)
                                if field.required {
                                    Text("*").foregroundColor(.red).font(.system(size: 13))
                                }
                            }
                            if field.required {
                                Text("Tələb olunur").font(.system(size: 10)).foregroundColor(.red)
                            }
                        }
                        .frame(width: 110, alignment: .leading)

                        Spacer()

                        Picker("", selection: mappingBinding(field.key)) {
                            Text("— (yoxdur)").tag(String?.none)
                            ForEach(headers, id: \.self) { h in
                                Text(h).tag(String?.some(h))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(currentValue(field.key) == nil ? .slate300 : .brand)
                        .frame(maxWidth: 160)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(
                        field.required && currentValue(field.key) == nil
                            ? Color(hex: "#FEF2F2") : Color.white
                    )
                }
            }
            .listStyle(.insetGrouped)

            if !mapping.isValid {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle").foregroundColor(.red)
                    Text("\"Məhsul adı\" və \"Satış qiyməti\" mütləq seçilməlidir")
                        .font(.system(size: 12)).foregroundColor(.red)
                }
                .padding(12)
                .background(Color(hex: "#FEF2F2"))
            }
        }
    }

    // MARK: - Preview

    private var previewView: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "doc.text").foregroundColor(Color(hex: "#059669")).font(.system(size: 13))
                Text(fileName).font(.system(size: 13, weight: .medium)).lineLimit(1)
                Text("· \(rows.count) sətir (\(validRows.count) etibarlı)")
                    .font(.system(size: 12)).foregroundColor(.slate400)
                Spacer()
                Button(selected.count == validRows.count ? "Seçimi sil" : "Hamısını seç") {
                    selected = selected.count == validRows.count ? [] : Set(validRows.map { $0.id })
                }
                .font(.system(size: 12)).foregroundColor(.brand)
            }
            .padding(.horizontal, 14).padding(.vertical, 10).background(Color.white)
            Divider()

            List(rows) { row in
                ImportRowCell(row: row, isSelected: selected.contains(row.id)) {
                    if row.isValid {
                        if selected.contains(row.id) { selected.remove(row.id) }
                        else { selected.insert(row.id) }
                    }
                }
                .listRowBackground(selected.contains(row.id) ? Color(hex: "#ECFDF5") : (row.isValid ? Color.white : Color(hex: "#FEF2F2")))
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            }
            .listStyle(.plain)
        }
    }

    private var doneView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill").font(.system(size: 64)).foregroundColor(Color(hex: "#10B981"))
            Text("\(selectedValid.count) məhsul idxal edildi").font(.system(size: 18, weight: .bold)).foregroundColor(.slate900)
            Spacer()
        }
    }

    // MARK: - File loading

    private func loadFile(url: URL) {
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }

        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.removeItem(at: tmp)
        guard (try? FileManager.default.copyItem(at: url, to: tmp)) != nil else {
            parseError = "Fayl kopyalana bilmədi"; return
        }

        fileName = url.lastPathComponent
        let ext = url.pathExtension.lowercased()

        if ext == "xlsx" || ext == "xls" {
            loadXLSX(from: tmp)
        } else {
            loadCSV(from: tmp)
        }
    }

    // MARK: - XLSX parser (server-side via /api/convert/xlsx)

    private func loadXLSX(from url: URL) {
        guard let fileData = try? Data(contentsOf: url) else {
            parseError = "XLSX faylı oxunmadı"; return
        }
        stage = .map  // show loading state via mapView spinner
        Task {
            do {
                let result = try await APIService.shared.convertXLSX(data: fileData, filename: url.lastPathComponent)
                headers = result.headers
                rawData = result.rows.map { row in
                    row.mapValues { "\($0)" }
                }
                mapping = suggestMapping(headers: headers)
                parseError = nil
            } catch {
                parseError = "XLSX emal edilmədi: \(error.localizedDescription)"
                stage = .pick
            }
        }
    }

    // MARK: - CSV parser

    private func loadCSV(from url: URL) {
        let text: String
        if let t = try? String(contentsOf: url, encoding: .utf8) { text = t }
        else if let t = try? String(contentsOf: url, encoding: .windowsCP1251) { text = t }
        else if let t = try? String(contentsOf: url, encoding: .isoLatin1) { text = t }
        else { parseError = "Fayl oxunmadı — UTF-8 formatını yoxlayın"; return }

        let firstLine = text.components(separatedBy: .newlines).first { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? ""
        let delimiter: Character = firstLine.filter { $0 == ";" }.count > firstLine.filter { $0 == "," }.count ? ";" : ","

        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else { parseError = "Fayl boşdur"; return }

        headers = parseCSVLine(lines[0], delimiter: delimiter)
            .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

        rawData = lines.dropFirst().compactMap { line in
            let cols = parseCSVLine(line, delimiter: delimiter)
            guard cols.count >= max(1, headers.count / 2) else { return nil }
            var dict: [String: String] = [:]
            for (i, h) in headers.enumerated() {
                dict[h] = i < cols.count ? cols[i].trimmingCharacters(in: .whitespaces) : ""
            }
            return dict
        }

        mapping = suggestMapping(headers: headers)
        parseError = nil
        stage = .map
    }

    // MARK: - Auto-suggest mapping (same aliases as web app)

    private func suggestMapping(headers: [String]) -> FieldMapping {
        let norm = headers.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        func find(_ aliases: [String]) -> String? {
            for alias in aliases {
                if let idx = norm.firstIndex(where: { $0 == alias || $0.contains(alias) }) {
                    return headers[idx]
                }
            }
            return nil
        }

        let saleCol  = find(["satış qiyməti", "satış", "sale price", "satiş qiymeti"])
        let qiymCol  = find(["qiymət", "qiymet", "price"])
        let costCol  = find(["alış qiyməti", "alış", "alish", "cost price", "cost", "alış qiymeti"])

        var m = FieldMapping()
        m.name      = find(["ad", "name", "məhsul adı", "məhsul", "mehsul", "product"])
        m.barcode   = find(["barkod", "barcode", "ean", "kod", "code"])
        m.price     = saleCol ?? qiymCol
        m.costPrice = saleCol != nil ? (costCol ?? qiymCol) : costCol
        m.category  = find(["kateqoriya", "category", "qrup", "group"])
        m.unit      = find(["ölçü vahidi", "vahid", "unit", "ölçü"])
        return m
    }

    // MARK: - Apply mapping to produce rows

    private func applyMapping() {
        func get(_ col: String?, from row: [String: String]) -> String {
            guard let col else { return "" }
            return row[col]?.trimmingCharacters(in: .whitespaces) ?? ""
        }

        rows = rawData.map { row in
            let name  = get(mapping.name, from: row)
            let price = Double(get(mapping.price, from: row).replacingOccurrences(of: ",", with: ".")) ?? 0
            let isValid = !name.isEmpty && price > 0
            return ImportRow(
                name: name,
                barcode: get(mapping.barcode, from: row),
                price: price,
                costPrice: Double(get(mapping.costPrice, from: row).replacingOccurrences(of: ",", with: ".")) ?? 0,
                category: { let c = get(mapping.category, from: row); return c.isEmpty ? "Digər" : c }(),
                unit: { let u = get(mapping.unit, from: row); return u.isEmpty ? "ədəd" : u }(),
                isValid: isValid,
                error: isValid ? nil : (name.isEmpty ? "Ad yoxdur" : "Qiymət yanlış")
            )
        }.filter { !$0.name.isEmpty || $0.price > 0 }

        selected = Set(rows.filter { $0.isValid }.map { $0.id })
        stage = .preview
    }

    // MARK: - CSV line parser

    private func parseCSVLine(_ line: String, delimiter: Character = ",") -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        for ch in line {
            if ch == "\"" { inQuotes.toggle() }
            else if ch == delimiter && !inQuotes {
                result.append(current.trimmingCharacters(in: CharacterSet(charactersIn: "\"")))
                current = ""
            } else { current.append(ch) }
        }
        result.append(current.trimmingCharacters(in: CharacterSet(charactersIn: "\"")))
        return result
    }

    // MARK: - Binding helpers for FieldMapping

    private func mappingBinding(_ kp: WritableKeyPath<FieldMapping, String?>) -> Binding<String?> {
        Binding(get: { mapping[keyPath: kp] }, set: { mapping[keyPath: kp] = $0 })
    }

    private func currentValue(_ kp: WritableKeyPath<FieldMapping, String?>) -> String? {
        mapping[keyPath: kp]
    }
}

// MARK: - Shared ImportRowCell

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
                        Text("· \(err)").font(.system(size: 11)).foregroundColor(.red)
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
