import SwiftUI

// MARK: - Pill / Chip

struct PillView<Content: View>: View {
    var background: Color = ToraTokens.surfaceChip
    var foreground: Color = ToraTokens.text2
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(spacing: 6) {
            content()
        }
        .font(ToraFont.pill)
        .foregroundStyle(foreground)
        .padding(.horizontal, 9)
        .frame(height: 22)
        .background(
            Capsule().fill(background)
        )
        .overlay(
            Capsule().stroke(ToraTokens.borderSoft, lineWidth: 0.5)
        )
        .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Keyboard shortcut chip

struct KbdView: View {
    let key: String

    var body: some View {
        Text(key)
            .font(ToraFont.kbd)
            .foregroundStyle(ToraTokens.text3)
            .padding(.horizontal, 5)
            .frame(minWidth: 18, minHeight: 18)
            .background(
                RoundedRectangle(cornerRadius: 4).fill(ToraTokens.surfaceChip)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4).stroke(ToraTokens.borderStrong, lineWidth: 0.5)
            )
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.toraAccent) private var accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ToraFont.body)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background(accent)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .brightness(configuration.isPressed ? -0.05 : 0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ToraFont.body)
            .foregroundStyle(ToraTokens.text)
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background(.ultraThinMaterial)
            .background(ToraTokens.surface3)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7).stroke(ToraTokens.borderSoft, lineWidth: 0.5)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ToraFont.bodySmall)
            .foregroundStyle(ToraTokens.text2)
            .padding(.horizontal, 8)
            .frame(height: 26)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed ? ToraTokens.surfaceChip : Color.clear)
            )
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var toraPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
extension ButtonStyle where Self == SecondaryButtonStyle {
    static var toraSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
extension ButtonStyle where Self == GhostButtonStyle {
    static var toraGhost: GhostButtonStyle { GhostButtonStyle() }
}

// MARK: - Glass card

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 10
    var padding: EdgeInsets = EdgeInsets(top: 12, leading: 12, bottom: 10, trailing: 12)

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial)
            .background(ToraTokens.surface3)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(ToraTokens.border, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 10) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Focus ring

struct FocusRing: ViewModifier {
    @Environment(\.toraAccent) private var accent
    let isFocused: Bool
    var cornerRadius: CGFloat = 10

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(isFocused ? accent : .clear, lineWidth: 0.5)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(isFocused ? accent.opacity(0.16) : .clear, lineWidth: 2)
                )
        )
    }
}

extension View {
    func focusRing(_ isFocused: Bool, cornerRadius: CGFloat = 10) -> some View {
        modifier(FocusRing(isFocused: isFocused, cornerRadius: cornerRadius))
    }
}
