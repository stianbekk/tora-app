import SwiftUI

struct NotificationToastView: View {
    let suggestion: SuggestionViewModel
    let onAccept: () -> Void
    let onDismiss: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image("Mascot")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .shadow(color: AccentPreset.tora.color.opacity(0.35), radius: 4, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Tora").font(.system(size: 12, weight: .bold))
                    Text("· now").font(.system(size: 11)).foregroundStyle(ToraTokens.text3)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: ToraIcon.xmark).font(.system(size: 11))
                    }
                    .buttonStyle(.toraGhost)
                    .frame(width: 22, height: 22)
                }

                Text(suggestion.title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(ToraTokens.text)
                    .lineLimit(2)

                HStack(spacing: 5) {
                    Image(systemName: suggestion.source == .slack ? ToraIcon.slack : ToraIcon.mail)
                        .font(.system(size: 11))
                    Text("\(suggestion.person) · \(suggestion.sourceLabel)")
                    if let customer = suggestion.customer {
                        Text("·")
                        Image(systemName: ToraIcon.building).font(.system(size: 11))
                        Text(customer)
                    }
                }
                .font(.system(size: 11.5))
                .foregroundStyle(ToraTokens.text3)
                .padding(.bottom, 6)

                HStack(spacing: 6) {
                    Button(action: onAccept) {
                        HStack(spacing: 6) {
                            Image(systemName: ToraIcon.check).font(.system(size: 11))
                            Text("Accept")
                        }
                    }
                    .buttonStyle(.toraPrimary)
                    Button("Dismiss", action: onDismiss)
                        .buttonStyle(.toraSecondary)
                }
            }
        }
        .padding(14)
        .frame(width: 360)
        .background(.ultraThinMaterial)
        .background(ToraTokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(ToraTokens.border, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.25), radius: 24, y: 12)
    }
}
