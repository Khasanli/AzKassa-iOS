import SwiftUI

// MARK: - Colors  (mirrors tailwind.config.ts)

extension Color {
    static let brand      = Color("BrandColor")   // #4F46E5
    static let brandHover = Color("BrandHover")   // #4338CA
    static let brandLight = Color("BrandLight")   // #EEF2FF
    static let sidebarBg  = Color("SidebarBG")    // #1E1B4B
    static let appBg      = Color("AppBG")        // #F8FAFC

    // Slate scale used throughout the web app
    static let slate900 = Color(hex: "#0F172A")
    static let slate800 = Color(hex: "#1E293B")
    static let slate700 = Color(hex: "#334155")
    static let slate600 = Color(hex: "#475569")
    static let slate500 = Color(hex: "#64748B")
    static let slate400 = Color(hex: "#94A3B8")
    static let slate300 = Color(hex: "#CBD5E1")
    static let slate200 = Color(hex: "#E2E8F0")
    static let slate100 = Color(hex: "#F1F5F9")
    static let slate50  = Color(hex: "#F8FAFC")
}

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Typography

extension Font {
    static let appTitle    = Font.system(size: 20, weight: .semibold)
    static let appHeadline = Font.system(size: 15, weight: .semibold)
    static let appBody     = Font.system(size: 14, weight: .regular)
    static let appCaption  = Font.system(size: 12, weight: .regular)
    static let appMono     = Font.system(size: 12, weight: .regular, design: .monospaced)
}

// MARK: - Shared components

struct AKCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.slate900.opacity(0.06), radius: 4, x: 0, y: 1)
    }
}

struct AKPrimaryButton: View {
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    init(_ title: String, isLoading: Bool = false, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title).font(.system(size: 14, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(isDisabled ? Color.slate300 : Color.brand)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .disabled(isDisabled || isLoading)
    }
}

struct AKTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
            }
        }
        .font(.appBody)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.slate100)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.slate200, lineWidth: 1))
    }
}

struct AKBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .cornerRadius(6)
    }
}

struct AKSectionHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.slate500)
            .tracking(0.8)
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Navigation bar appearance

struct AKNavigationStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

extension View {
    func akNavigationStyle() -> some View { modifier(AKNavigationStyle()) }
}
