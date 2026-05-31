import SwiftUI
import UniformTypeIdentifiers

// MARK: - Qaimə (AI Document Import) — mirrors web DocumentImportModal

struct QaimeImportView: View {
    let onImport: ([ImportRow]) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var stage: Stage = .pick
    @State private var rows: [ImportRow] = []
    @State private var selected: Set<UUID> = []
    @State private var isAnalyzing = false
    @State private var errorMsg: String?
    @State private var showPicker = false
    @State private var fileName = ""
    @State private var apiKey: String = UserDefaults.standard.string(forKey: "anthropic_api_key") ?? ""

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
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#F5F3FF"))
                    .frame(width: 80, height: 80)
                    .overlay(Image(systemName: "doc.text.magnifyingglass").font(.system(size: 36)).foregroundColor(Color(hex: "#8B5CF6")))

                Text("Qaimə / Faktura Analizi")
                    .font(.system(size: 18, weight: .bold)).foregroundColor(.slate900)
                Text("PDF, şəkil və ya mətn faylını yükləyin.\nClaude AI məhsulları avtomatik aşkarlayacaq.")
                    .font(.system(size: 14)).foregroundColor(.slate500)
                    .multilineTextAlignment(.center)
            }

            // API key inline input
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "key.fill").font(.system(size: 11)).foregroundColor(Color(hex: "#8B5CF6"))
                    Text("Anthropic API Açarı").font(.system(size: 13, weight: .medium)).foregroundColor(.slate700)
                }
                SecureField("sk-ant-...", text: $apiKey)
                    .font(.system(size: 13, design: .monospaced))
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(
                        apiKey.isEmpty ? Color(hex: "#DDD6FE") : Color(hex: "#8B5CF6"), lineWidth: 1))
                    .onChange(of: apiKey) { v in
                        UserDefaults.standard.set(v, forKey: "anthropic_api_key")
                    }
                if apiKey.isEmpty {
                    Text("Analiz üçün Claude API açarı tələb olunur")
                        .font(.system(size: 11)).foregroundColor(Color(hex: "#8B5CF6"))
                }
            }
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                Button { showPicker = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.badge.plus")
                        Text("Fayl seçin")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(apiKey.isEmpty ? Color.slate300 : Color(hex: "#8B5CF6"))
                    .foregroundColor(.white).cornerRadius(10)
                }
                .padding(.horizontal, 24)
                .disabled(apiKey.isEmpty)

                Text("PDF · PNG · JPG · TXT dəstəklənir")
                    .font(.system(size: 12)).foregroundColor(.slate400)
            }

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
        .fileImporter(
            isPresented: $showPicker,
            allowedContentTypes: [.data]
        ) { result in
            switch result {
            case .success(let url): analyzeDocument(url: url)
            case .failure(let e): errorMsg = e.localizedDescription
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

    // MARK: - Preview (same as ExcelImport)

    private var previewView: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "checkmark.seal.fill").foregroundColor(Color(hex: "#8B5CF6")).font(.system(size: 13))
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
                        if selected.contains(row.id) { selected.remove(row.id) } else { selected.insert(row.id) }
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
            Image(systemName: "checkmark.circle.fill").font(.system(size: 64)).foregroundColor(Color(hex: "#10B981"))
            Text("\(selectedValid.count) məhsul idxal edildi").font(.system(size: 18, weight: .bold)).foregroundColor(.slate900)
            Button("Bağla") { dismiss() }.foregroundColor(.brand)
            Spacer()
        }
    }

    // MARK: - AI Analysis

    private func analyzeDocument(url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        fileName = url.lastPathComponent
        stage = .analyzing

        Task {
            do {
                let content: String
                if url.pathExtension.lowercased() == "pdf" {
                    content = "[PDF fayl: \(url.lastPathComponent)] - Məzmunu oxumaq üçün mətn formatına çevirin"
                } else {
                    content = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
                }
                let extracted = try await callClaudeAPI(text: content)
                rows = extracted
                selected = Set(rows.filter(\.isValid).map(\.id))
                stage = .preview
            } catch {
                errorMsg = error.localizedDescription
                stage = .pick
            }
        }
    }

    private func callClaudeAPI(text: String) async throws -> [ImportRow] {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "API açarını yuxarıda daxil edin"])
        }

        let prompt = """
        Bu sənəddən məhsul siyahısını çıxar. JSON massiv formatında cavab ver:
        [{"name":"...","price":0.0,"costPrice":0.0,"barcode":"","category":"Digər","unit":"ədəd"}]
        Yalnız JSON cavabı ver, heç bir əlavə mətn olmadan.

        Sənəd:
        \(text.prefix(4000))
        """

        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 2048,
            "messages": [["role": "user", "content": prompt]]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: req)
        guard let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = (resp["content"] as? [[String: Any]])?.first?["text"] as? String
        else { throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "AI cavabı alınmadı"]) }

        let jsonStart = content.firstIndex(of: "[") ?? content.startIndex
        let jsonEnd   = content.lastIndex(of: "]").map { content.index(after: $0) } ?? content.endIndex
        let jsonStr   = String(content[jsonStart..<jsonEnd])

        guard let jsonData = jsonStr.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]]
        else { throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Nəticə emal edilmədi"]) }

        return parsed.map { item in
            let name  = item["name"] as? String ?? ""
            let price = (item["price"] as? Double) ?? Double(item["price"] as? String ?? "0") ?? 0
            return ImportRow(
                name: name,
                barcode: item["barcode"] as? String ?? "",
                price: price,
                costPrice: (item["costPrice"] as? Double) ?? 0,
                category: item["category"] as? String ?? "Digər",
                unit: item["unit"] as? String ?? "ədəd",
                isValid: !name.isEmpty && price > 0
            )
        }
    }
}
