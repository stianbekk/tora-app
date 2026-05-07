import SwiftUI

// MARK: - Accent

enum AccentPreset: String, CaseIterable, Identifiable {
    case tora
    case amber
    case emerald
    case crimson
    case slate

    var id: String { rawValue }

    var hex: String {
        switch self {
        case .tora:    return "#5D4FE8"
        case .amber:   return "#F59E0B"
        case .emerald: return "#10B981"
        case .crimson: return "#EF4444"
        case .slate:   return "#64748B"
        }
    }

    var displayName: String {
        switch self {
        case .tora:    return "Tora"
        case .amber:   return "Amber"
        case .emerald: return "Emerald"
        case .crimson: return "Crimson"
        case .slate:   return "Slate"
        }
    }

    var color: Color { Color(hex: hex) }
}

// MARK: - Theme tokens

extension Color {
    init(hex: String, alpha: Double = 1.0) {
        let trimmed = hex.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    // Backgrounds
    static let toraSurface       = Color("Surface",      bundle: nil)
    static let toraSurface2      = Color("Surface2",     bundle: nil)
    static let toraSurface3      = Color("Surface3",     bundle: nil)
    static let toraSurfaceChip   = Color("SurfaceChip",  bundle: nil)

    // Borders
    static let toraBorder        = Color("Border",       bundle: nil)
    static let toraBorderSoft    = Color("BorderSoft",   bundle: nil)
    static let toraBorderStrong  = Color("BorderStrong", bundle: nil)

    // Text
    static let toraText   = Color("Text",   bundle: nil)
    static let toraText2  = Color("Text2",  bundle: nil)
    static let toraText3  = Color("Text3",  bundle: nil)
    static let toraText4  = Color("Text4",  bundle: nil)

    // Light/dark dynamic palette resolved manually so we don't depend on Asset Catalog at this stage.
    static func toraDynamic(light: Color, dark: Color) -> Color {
        Color(NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor(dark)
                : NSColor(light)
        })
    }
}

// MARK: - Tokens (resolved values until asset catalog colors are added)

enum ToraTokens {
    static let surface       = Color.toraDynamic(light: Color(hex: "#FFFFFF", alpha: 0.55), dark: Color(hex: "#22242A", alpha: 0.5))
    static let surface2      = Color.toraDynamic(light: Color(hex: "#FFFFFF", alpha: 0.38), dark: Color(hex: "#1C1E24", alpha: 0.5))
    static let surface3      = Color.toraDynamic(light: Color(hex: "#FFFFFF", alpha: 0.5),  dark: Color(hex: "#3C3E46", alpha: 0.5))
    static let surfaceChip   = Color.toraDynamic(light: Color.black.opacity(0.045),         dark: Color.white.opacity(0.07))
    static let border        = Color.toraDynamic(light: Color.white.opacity(0.6),           dark: Color.white.opacity(0.10))
    static let borderSoft    = Color.toraDynamic(light: Color.black.opacity(0.06),          dark: Color.white.opacity(0.06))
    static let borderStrong  = Color.toraDynamic(light: Color.black.opacity(0.12),          dark: Color.white.opacity(0.18))
    static let text          = Color.toraDynamic(light: Color(hex: "#0E1116"),              dark: Color(hex: "#F2F3F5"))
    static let text2         = Color.toraDynamic(light: Color(hex: "#2C3038"),              dark: Color(hex: "#D6D9DF"))
    static let text3         = Color.toraDynamic(light: Color(hex: "#4F5560"),              dark: Color(hex: "#9AA0AA"))
    static let text4         = Color.toraDynamic(light: Color(hex: "#7A8090"),              dark: Color(hex: "#6C7280"))
}

// MARK: - Accent environment

private struct AccentColorKey: EnvironmentKey {
    static let defaultValue: Color = AccentPreset.tora.color
}

extension EnvironmentValues {
    var toraAccent: Color {
        get { self[AccentColorKey.self] }
        set { self[AccentColorKey.self] = newValue }
    }
}
