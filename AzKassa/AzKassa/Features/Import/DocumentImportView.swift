import SwiftUI
import UniformTypeIdentifiers

// MARK: - Qaimə (AI Document Import) — calls /api/ai/analyze on the backend

struct QaimeImportView: View {
    let onImport: ([ImportRow]) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var stage: Stage = .pick
    @State private var rows: [ImportRow] = []
    @State private var selected: Set<UUID> = []
    @State private var errorMsg: String?
    @State private var showPicker = false
    @State private var fileName = ""

    enum Stage { case pick, analyzing, preview, done }

    var selectedValid: [ImportRow] { rows.filter { $0.isValid && selected.contains($0.id) } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                switch stage {
                case .pick:      pickView
                case .analyzing: analyzingView
                case .preview:   previewView
                case .done:      doneView
                }
            }
            .navigationTitle("Qaimə İdxalı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Ləğv et") { dismiss() }
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
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "#F5F3FF"))
                    .frame(width: 88, height: 88)
                    .overlay(Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 38)).foregroundColor(Color(hex: "#8B5CF6")))

                Text("Qaimə / Faktura Analizi")
                    .font(.system(size: 20, weight: .bold)).foregroundColor(.slate900)
                Text("PDF, şəkil və ya mətn faylını yükləyin.\nClaude AI məhsulları avtomatik aşkarlayacaq.")
                    .font(.system(size: 14)).foregroundColor(.slate500)
                    .multilineTextAlignment(.center)
            }

            Button { showPicker = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.badge.plus")
                    Text("Fayl seçin")
                }
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(Color(hex: "#8B5CF6"))
                .foregroundColor(.white).cornerRadius(12)
            }
            .padding(.horizontal, 24)

            Text("PDF · PNG · JPG · TXT dəstəklənir")
                .font(.system(size: 12)).foregroundColor(.slate400)

            if let err = errorMsg {
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
            case .success(let url): analyzeDocument(url: url)
            case .failure(let e):  errorMsg = e.localizedDescription
            }
        }
    }

    // MARK: - Analyzing

    private var analyzingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView().scaleEffect(1.5).tint(Color(hex: "#8B5CF6"))
            Text("Claude AI analiz edir...")
                .font(.system(size: 16, weight: .semibold)).foregroundColor(.slate700)
            Text(fileName).font(.appBody).foregroundColor(.slate400)
            Spacer()
        }
        .background(Color.appBg)
    }

    // MARK: - Preview

    private var previewView: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(Color(hex: "#8B5CF6")).font(.system(size: 13))
                Text(fileName).font(.system(size: 13, weight: .medium)).lineLimit(1)
                Text("· \(rows.count) məhsul tapıldı").font(.system(size: 12)).foregroundColor(.slate400)
                Spacer()
                Button(selected.count == rows.filter(\.isValid).count ? "Seçimi sil" : "Hamısını seç") {
                    let valid = rows.filter(\.isValid).map(\.id)
                    selected = selected.count == valid.count ? [] : Set(valid)
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
                .listRowBackground(selected.contains(row.id) ? Color(hex: "#ECFDF5") : Color.white)
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
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
            Button("Bağla") { dismiss() }.foregroundColor(.brand)
            Spacer()
        }
    }

    // MARK: - Backend AI call

    private func analyzeDocument(url: URL) {
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        fileName = url.lastPathComponent
        stage = .analyzing
        errorMsg = nil

        // Copy to temp location so we can read it
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.removeItem(at: tmp)
        try? FileManager.default.copyItem(at: url, to: tmp)

        let text: String
        if let content = try? String(contentsOf: tmp, encoding: .utf8) {
            text = content
        } else if let content = try? String(contentsOf: tmp, encoding: .isoLatin1) {
            text = content
        } else {
            text = "[\(url.lastPathComponent) - məzmun oxunmadı, fayl adı analiz edilir]"
        }

        Task {
            do {
                let products = try await APIService.shared.analyzeDocument(text: text)
                rows = products.compactMap { item in
                    let name  = item["name"] as? String ?? ""
                    let price = (item["price"] as? Double) ?? Double(item["price"] as? String ?? "") ?? 0
                    guard !name.isEmpty else { return nil }
                    return ImportRow(
                        name: name,
                        barcode: item["barcode"] as? String ?? "",
                        price: price,
                        costPrice: (item["costPrice"] as? Double) ?? 0,
                        category: item["category"] as? String ?? "Digər",
                        unit: item["unit"] as? String ?? "ədəd",
                        isValid: !name.isEmpty && price > 0,
                        error: (name.isEmpty || price <= 0) ? "Yanlış məlumat" : nil
                    )
                }
                selected = Set(rows.filter(\.isValid).map(\.id))
                stage = .preview
            } catch {
                errorMsg = error.localizedDescription
                stage = .pick
            }
        }
    }
}
