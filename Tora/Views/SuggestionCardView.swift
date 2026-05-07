import SwiftUI

// MARK: - Suggestion card

/// Renders a single suggestion. Used in popover (focused, top suggestion) and
/// task list Inbox view (full list).
struct SuggestionCardView: View {
    @Environment(\.toraAccent) private var accent

    let suggestion: SuggestionViewModel
    let isFocused: Bool
    let onAccept: () -> Void
    let onDismiss: () -> Void
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 7)
            title
                .padding(.bottom, 6)
            if let snippet = suggestion.snippet {
                snippetView(snippet)
                    .padding(.bottom, 10)
            }
            metaChips
                .padding(.bottom, 10)
            actions
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .focusRing(isFocused)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 7) {
            sourceIcon
            Text(suggestion.person)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ToraTokens.text)
            Text("· \(suggestion.sourceLabel)")
                .font(.system(size: 11.5))
                .foregroundStyle(ToraTokens.text3)
            Spacer(minLength: 0)
            Text(suggestion.receivedAt)
                .font(ToraFont.mono)
                .foregroundStyle(ToraTokens.text4)
        }
    }

    private var sourceIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(ToraTokens.surface3)
                .frame(width: 18, height: 18)
            Image(systemName: suggestion.source == .slack ? ToraIcon.slack : ToraIcon.mail)
                .font(.system(size: 10))
                .foregroundStyle(ToraTokens.text3)
        }
    }

    // MARK: Title / snippet

    private var title: some View {
        Text(suggestion.title)
            .font(ToraFont.cardTitle)
            .foregroundStyle(ToraTokens.text)
            .lineLimit(2)
    }

    private func snippetView(_ snippet: String) -> some View {
        Text(snippet)
            .font(ToraFont.snippet)
            .foregroundStyle(ToraTokens.text3)
            .lineLimit(2)
    }

    // MARK: Meta chips

    private var metaChips: some View {
        HStack(spacing: 5) {
            if let due = suggestion.due {
                PillView(
                    background: suggestion.urgency == .high ? accent.opacity(0.13) : ToraTokens.surfaceChip,
                    foreground: suggestion.urgency == .high ? accent : ToraTokens.text2
                ) {
                    Image(systemName: ToraIcon.clock).font(.system(size: 10))
                    Text(due)
                }
            }
            if let customer = suggestion.customer {
                PillView {
                    Image(systemName: ToraIcon.building).font(.system(size: 10))
                    Text(customer)
                }
            }
            if let product = suggestion.product {
                PillView {
                    Image(systemName: ToraIcon.tag).font(.system(size: 10))
                    Text(product)
                }
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: Actions

    private var actions: some View {
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

            Spacer(minLength: 0)

            if isFocused {
                HStack(spacing: 4) {
                    KbdView(key: "⌘")
                    KbdView(key: "↵")
                }
            }
        }
    }
}

// MARK: - View model

/// Display-friendly snapshot of a suggestion, decoupled from the database type
/// so the view doesn't need a live GRDB record.
struct SuggestionViewModel: Identifiable, Hashable {
    let id: String
    let source: Source.Kind
    let sourceLabel: String
    let person: String
    let title: String
    let snippet: String?
    let urgency: Suggestion.Urgency
    let due: String?
    let customer: String?
    let product: String?
    let receivedAt: String
}
