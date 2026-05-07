import SwiftUI

struct PopoverView: View {
    @Environment(AppState.self) private var state
    @Environment(\.toraAccent) private var accent

    let onOpenTaskList: (SidebarFilter) -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(ToraTokens.borderSoft)
            inboxSection
            Spacer(minLength: 0)
            taskFooter
            sourcesBar

            // Hidden buttons exist solely to host keyboard shortcuts. SwiftUI
            // requires a Button to bind a `.keyboardShortcut`.
            keyboardShortcutsLayer
        }
        .frame(width: 380)
        .frame(minHeight: 360)
        .background(.ultraThinMaterial)
        .background(ToraTokens.surface)
    }

    private var keyboardShortcutsLayer: some View {
        VStack(spacing: 0) {
            Button("") { acceptFocused() }
                .keyboardShortcut(.return, modifiers: .command)
            Button("") { dismissFocused() }
                .keyboardShortcut(.delete, modifiers: .command)
            Button("") { focusPrevious() }
                .keyboardShortcut(.upArrow, modifiers: [])
            Button("") { focusNext() }
                .keyboardShortcut(.downArrow, modifiers: [])
        }
        .frame(width: 0, height: 0)
        .opacity(0)
        .allowsHitTesting(false)
    }

    private func acceptFocused() {
        guard let id = state.focusedSuggestionId else { return }
        if state.inlineEditId == id { return } // editor handles ↵ itself
        state.inlineEditId = id
    }

    private func dismissFocused() {
        guard let id = state.focusedSuggestionId else { return }
        state.dismiss(suggestionId: id)
    }

    private func focusPrevious() {
        guard !state.suggestions.isEmpty else { return }
        let ids = state.suggestions.map(\.id)
        guard let current = state.focusedSuggestionId,
              let idx = ids.firstIndex(of: current) else {
            state.focusedSuggestionId = ids.first
            return
        }
        state.focusedSuggestionId = ids[max(0, idx - 1)]
    }

    private func focusNext() {
        guard !state.suggestions.isEmpty else { return }
        let ids = state.suggestions.map(\.id)
        guard let current = state.focusedSuggestionId,
              let idx = ids.firstIndex(of: current) else {
            state.focusedSuggestionId = ids.first
            return
        }
        state.focusedSuggestionId = ids[min(ids.count - 1, idx + 1)]
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 8) {
            GlyphView(variant: state.glyphVariant, size: 18)
            Text("Tora")
                .font(.system(size: 14, weight: .bold))
                .tracking(-0.1)
            Spacer()
            Button(action: onOpenSettings) {
                Image(systemName: ToraIcon.settings).font(.system(size: 13))
            }
            .buttonStyle(.toraGhost)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    // MARK: Inbox

    private var inboxSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text("INBOX")
                    .font(.system(size: 10.5, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(ToraTokens.text3)
                if state.pendingCount > 0 {
                    Text("\(state.pendingCount)")
                        .font(ToraFont.badge)
                        .foregroundStyle(accent)
                        .padding(.horizontal, 5)
                        .frame(minWidth: 16, minHeight: 15)
                        .background(
                            Capsule().fill(accent.opacity(0.13))
                        )
                }
                Spacer()
                if state.pendingCount > 0 {
                    Button {
                        onOpenTaskList(.inbox)
                    } label: {
                        HStack(spacing: 4) {
                            Text("Open inbox")
                            Image(systemName: ToraIcon.arrow).font(.system(size: 10))
                        }
                    }
                    .buttonStyle(.toraGhost)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 4)

            inboxContent
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
        .padding(.top, 10)
    }

    @ViewBuilder
    private var inboxContent: some View {
        if let top = state.suggestions.first {
            VStack(spacing: 8) {
                if state.inlineEditId == top.id {
                    InlineAcceptEditor(
                        suggestion: top,
                        customers: state.customerNames,
                        products: state.productNames,
                        onConfirm: { edits in state.accept(suggestionId: top.id, edits: edits) },
                        onCancel: { state.inlineEditId = nil }
                    )
                } else {
                    SuggestionCardView(
                        suggestion: top,
                        isFocused: state.focusedSuggestionId == top.id,
                        onAccept: { state.inlineEditId = top.id },
                        onDismiss: { state.dismiss(suggestionId: top.id) },
                        onTap: {
                            state.focusedSuggestionId = top.id
                            state.inlineEditId = top.id
                        }
                    )
                }

                if state.suggestions.count > 1 {
                    Button {
                        onOpenTaskList(.inbox)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: ToraIcon.inbox).font(.system(size: 11))
                            Text("\(state.suggestions.count - 1) more in inbox")
                            Spacer()
                            Image(systemName: ToraIcon.chev).font(.system(size: 10))
                        }
                        .font(.system(size: 11.5))
                        .foregroundStyle(ToraTokens.text3)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(ToraTokens.surfaceChip)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(ToraTokens.borderStrong, style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        } else {
            EmptyInboxView(onOpenTaskList: { onOpenTaskList(.allOpen) })
        }
    }

    // MARK: Task footer

    private var taskFooter: some View {
        Button {
            onOpenTaskList(.today)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: ToraIcon.list).font(.system(size: 13)).foregroundStyle(ToraTokens.text3)
                Text("My tasks")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(ToraTokens.text)
                PillView { Text("\(state.openTaskCount)") }
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: ToraIcon.check).font(.system(size: 10))
                    Text("\(state.completedTodayCount) today")
                }
                .font(.system(size: 11))
                .foregroundStyle(ToraTokens.text3)
                Image(systemName: ToraIcon.chev).font(.system(size: 10)).foregroundStyle(ToraTokens.text4)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(ToraTokens.surface2)
            .overlay(alignment: .top) { Divider().background(ToraTokens.borderSoft) }
        }
        .buttonStyle(.plain)
    }

    // MARK: Sources bar

    private var sourcesBar: some View {
        HStack(spacing: 10) {
            Text("Sources").font(.system(size: 11)).foregroundStyle(ToraTokens.text3)
            sourceIndicator(name: "Slack", connected: state.slackConnected)
            sourceIndicator(name: "Gmail", connected: false)
            Spacer()
            Text("v0.1.0").font(.system(size: 10, design: .monospaced)).foregroundStyle(ToraTokens.text4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(ToraTokens.surface2)
        .overlay(alignment: .top) { Divider().background(ToraTokens.borderSoft) }
    }

    private func sourceIndicator(name: String, connected: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(connected ? Color.green : ToraTokens.text4)
                .frame(width: 6, height: 6)
            Text(name).font(.system(size: 11)).foregroundStyle(ToraTokens.text3)
        }
    }
}

// MARK: - Empty inbox

struct EmptyInboxView: View {
    let onOpenTaskList: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(ToraTokens.surface3)
                    .frame(width: 44, height: 44)
                Image(systemName: ToraIcon.check)
                    .font(.system(size: 18))
                    .foregroundStyle(ToraTokens.text3)
            }
            Text("You're all caught up")
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(ToraTokens.text)
            Text("Tora is watching Slack and Gmail. New suggestions will appear here as they come in.")
                .font(.system(size: 11.5))
                .foregroundStyle(ToraTokens.text3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 240)
            Button {
                onOpenTaskList()
            } label: {
                HStack(spacing: 6) {
                    Text("View task list")
                    Image(systemName: ToraIcon.arrow).font(.system(size: 10))
                }
            }
            .buttonStyle(.toraGhost)
            .padding(.top, 4)
        }
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
    }
}
