import SwiftUI

enum ToraFont {
    static let windowTitle    = Font.system(size: 13,   weight: .semibold)
    static let sectionHeader  = Font.system(size: 10.5, weight: .bold).leading(.tight)
    static let cardTitle      = Font.system(size: 13.5, weight: .semibold)
    static let body           = Font.system(size: 12.5, weight: .medium)
    static let bodySmall      = Font.system(size: 12,   weight: .medium)
    static let snippet        = Font.system(size: 11.5, weight: .regular).italic()
    static let pill           = Font.system(size: 11.5, weight: .medium)
    static let kbd            = Font.system(size: 10.5, weight: .medium)
    static let badge          = Font.system(size: 10,   weight: .bold)
    static let mono           = Font.system(size: 11,   weight: .regular, design: .monospaced)
}

struct UppercaseSection: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(ToraFont.sectionHeader)
            .textCase(.uppercase)
            .tracking(0.6)
            .foregroundStyle(ToraTokens.text3)
    }
}

extension View {
    func uppercaseSectionStyle() -> some View {
        modifier(UppercaseSection())
    }
}
