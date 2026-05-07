import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case sources
    case ai
    case customers
    case shortcuts
    case notifications

    var id: String { rawValue }

    var label: String {
        switch self {
        case .general:       return "General"
        case .sources:       return "Sources"
        case .ai:            return "AI Extraction"
        case .customers:     return "Customers & Products"
        case .shortcuts:     return "Shortcuts"
        case .notifications: return "Notifications"
        }
    }

    var icon: String {
        switch self {
        case .general:       return ToraIcon.settings
        case .sources:       return ToraIcon.inbox
        case .ai:            return ToraIcon.bolt
        case .customers:     return ToraIcon.building
        case .shortcuts:     return ToraIcon.list
        case .notifications: return ToraIcon.bell
        }
    }
}

struct SettingsView: View {
    let coordinator: AppCoordinator?
    @State private var selectedTab: SettingsTab = .sources

    init(coordinator: AppCoordinator? = nil) {
        self.coordinator = coordinator
    }

    var body: some View {
        HSplitView {
            sidebar
                .frame(minWidth: 200, idealWidth: 200, maxWidth: 240)
            ScrollView {
                content
                    .padding(.horizontal, 32)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(.ultraThinMaterial)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(SettingsTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon).font(.system(size: 13)).frame(width: 14)
                        Text(tab.label)
                            .font(.system(size: 12.5, weight: selectedTab == tab ? .semibold : .medium))
                        Spacer()
                    }
                    .foregroundStyle(selectedTab == tab ? AccentPreset.tora.color : ToraTokens.text2)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedTab == tab ? AccentPreset.tora.color.opacity(0.13) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(ToraTokens.surface2)
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .general:       GeneralPane()
        case .sources:       SourcesPane(coordinator: coordinator)
        case .ai:            AIExtractionPane(coordinator: coordinator)
        case .customers:     CustomersPane()
        case .shortcuts:     ShortcutsPane()
        case .notifications: NotificationsPane()
        }
    }
}

// MARK: - Reusable building blocks

private struct PaneHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 19, weight: .bold))
                .tracking(-0.3)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12.5))
                    .foregroundStyle(ToraTokens.text3)
                    .frame(maxWidth: 480, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.bottom, 22)
    }
}

private struct Section<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(spacing: 0) { content() }
            .background(ToraTokens.surface2)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(ToraTokens.border, lineWidth: 0.5)
            )
            .padding(.bottom, 14)
    }
}

private struct SectionRow<Leading: View, Trailing: View>: View {
    var divider: Bool
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing

    init(
        divider: Bool = true,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.divider = divider
        self.leading = leading
        self.trailing = trailing
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                leading()
                Spacer()
                trailing()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            if divider { Divider().background(ToraTokens.border) }
        }
    }
}

private struct ToggleRow: View {
    let title: String
    let subtitle: String
    @State private var isOn: Bool
    var divider: Bool

    init(title: String, subtitle: String, initialValue: Bool = true, divider: Bool = true) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = State(initialValue: initialValue)
        self.divider = divider
    }

    var body: some View {
        SectionRow(divider: divider) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .semibold))
                Text(subtitle).font(.system(size: 11.5)).foregroundStyle(ToraTokens.text3)
            }
        } trailing: {
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
}

// MARK: - General

private struct GeneralPane: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PaneHeader(title: "General")

            Section {
                ToggleRow(title: "Launch at login",
                          subtitle: "Start Tora when you log in to your Mac",
                          initialValue: true)
                ToggleRow(title: "Show in Dock",
                          subtitle: "Tora normally lives only in the menu bar",
                          initialValue: false)
                SectionRow(divider: false) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Appearance").font(.system(size: 13, weight: .semibold))
                        Text("Match system, or override").font(.system(size: 11.5)).foregroundStyle(ToraTokens.text3)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { state.appearance },
                        set: { state.appearance = $0 }
                    )) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 140)
                }
            }

            Section {
                SectionRow(divider: false) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Accent color").font(.system(size: 13, weight: .semibold))
                        Text("Used for buttons, badges, and highlights").font(.system(size: 11.5)).foregroundStyle(ToraTokens.text3)
                    }
                } trailing: {
                    HStack(spacing: 6) {
                        ForEach(AccentPreset.allCases) { preset in
                            Button {
                                state.accent = preset
                            } label: {
                                Circle()
                                    .fill(preset.color)
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        Circle().stroke(state.accent == preset ? ToraTokens.text : .clear, lineWidth: 1.5)
                                    )
                            }
                            .buttonStyle(.plain)
                            .help(preset.displayName)
                        }
                    }
                }
            }

            Section {
                SectionRow(divider: false) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Menu bar icon").font(.system(size: 13, weight: .semibold))
                        Text("Choose your Tora glyph").font(.system(size: 11.5)).foregroundStyle(ToraTokens.text3)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { state.glyphVariant },
                        set: { state.glyphVariant = $0 }
                    )) {
                        ForEach(GlyphView.Variant.allCases) { v in
                            Text(v.displayName).tag(v)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 200)
                }
            }
        }
    }
}

// MARK: - Sources

private struct SourcesPane: View {
    let coordinator: AppCoordinator?
    @State private var slackToken: String = ""
    @State private var slackTokenSet: Bool = false

    init(coordinator: AppCoordinator?) {
        self.coordinator = coordinator
        _slackTokenSet = State(initialValue: coordinator?.keychain.get(.slackBotToken) != nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PaneHeader(
                title: "Sources",
                subtitle: "Connected channels Tora watches for actionable messages. Tora processes through AI and only stores extracted task metadata — never raw messages."
            )

            Section {
                sourceRow(
                    label: "Slack",
                    subtitle: slackTokenSet ? "Bot token configured" : "Not connected",
                    connected: slackTokenSet,
                    divider: true
                )
                sourceRow(label: "Gmail", subtitle: "Not connected (v1)", connected: false, divider: false)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("SLACK BOT TOKEN").uppercaseSectionStyle()
                Text("Paste a Slack bot token (xoxb-…) to start receiving events. See docs/setup-slack.md for app creation and ngrok setup.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(ToraTokens.text3)
                HStack(spacing: 6) {
                    SecureField("xoxb-…", text: $slackToken)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12.5, design: .monospaced))
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(ToraTokens.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(ToraTokens.borderStrong, lineWidth: 0.5))
                    Button("Save") {
                        let coord = coordinator
                        let token = slackToken
                        Task { await coord?.updateSlackToken(token) }
                        slackToken = ""
                        slackTokenSet = true
                    }
                    .buttonStyle(.toraPrimary)
                    .disabled(slackToken.isEmpty)
                }
            }
            .padding(.top, 18)
        }
    }

    private func sourceRow(label: String, subtitle: String, connected: Bool, divider: Bool) -> some View {
        SectionRow(divider: divider) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(label == "Slack" ? Color(red: 0.29, green: 0.08, blue: 0.29).opacity(0.08)
                                               : Color(red: 0.85, green: 0.19, blue: 0.15).opacity(0.08))
                        .frame(width: 36, height: 36)
                    Image(systemName: label == "Slack" ? ToraIcon.slack : ToraIcon.mail)
                        .font(.system(size: 18))
                        .foregroundStyle(label == "Slack" ? Color(red: 0.29, green: 0.08, blue: 0.29)
                                                          : Color(red: 0.85, green: 0.19, blue: 0.15))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.system(size: 13, weight: .semibold))
                    Text(subtitle).font(.system(size: 11.5)).foregroundStyle(ToraTokens.text3)
                }
            }
        } trailing: {
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Circle().fill(connected ? .green : ToraTokens.text4).frame(width: 6, height: 6)
                    Text(connected ? "Connected" : "Disconnected")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(connected ? .green : ToraTokens.text3)
                }
                Button(connected ? "Configure" : "Connect") {}
                    .buttonStyle(.toraSecondary)
            }
        }
    }
}

// MARK: - AI Extraction

private struct AIExtractionPane: View {
    let coordinator: AppCoordinator?
    @State private var apiKey: String = ""
    @State private var apiKeySet: Bool = false
    @State private var batchInterval: String = "30 seconds"

    init(coordinator: AppCoordinator?) {
        self.coordinator = coordinator
        _apiKeySet = State(initialValue: coordinator?.keychain.get(.openAIAPIKey) != nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PaneHeader(
                title: "AI Extraction",
                subtitle: "Tora uses OpenAI structured outputs to detect actionable tasks. Adjust the model and your API key here."
            )

            Section {
                SectionRow {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Model").font(.system(size: 13, weight: .semibold))
                        Text("$0.75/M in · $4.50/M out · structured output")
                            .font(.system(size: 11.5))
                            .foregroundStyle(ToraTokens.text3)
                    }
                } trailing: {
                    Picker("", selection: .constant(ModelOption.defaultModel.id)) {
                        ForEach(ModelOption.allOptions, id: \.id) { m in
                            Text(m.displayName).tag(m.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 180)
                }

                SectionRow {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("OpenAI API key").font(.system(size: 13, weight: .semibold))
                        Text(apiKeySet ? "Stored in macOS Keychain" : "Not configured")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(ToraTokens.text3)
                    }
                } trailing: {
                    HStack(spacing: 6) {
                        SecureField("sk-…", text: $apiKey)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11.5, design: .monospaced))
                            .padding(.horizontal, 10)
                            .frame(width: 200, height: 28)
                            .background(ToraTokens.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            .overlay(RoundedRectangle(cornerRadius: 7).stroke(ToraTokens.borderStrong, lineWidth: 0.5))
                        Button("Save") {
                            let coord = coordinator
                            let key = apiKey
                            Task { await coord?.updateAPIKey(key) }
                            apiKey = ""
                            apiKeySet = true
                        }
                        .buttonStyle(.toraSecondary)
                        .disabled(apiKey.isEmpty)
                    }
                }

                SectionRow(divider: false) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Batch interval").font(.system(size: 13, weight: .semibold))
                        Text("Buffer messages before extracting").font(.system(size: 11.5)).foregroundStyle(ToraTokens.text3)
                    }
                } trailing: {
                    Picker("", selection: $batchInterval) {
                        Text("10 seconds").tag("10 seconds")
                        Text("30 seconds").tag("30 seconds")
                        Text("60 seconds").tag("60 seconds")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 140)
                }
            }

            Text("USAGE THIS MONTH").uppercaseSectionStyle().padding(.bottom, 10)

            HStack(spacing: 10) {
                StatTile(label: "Messages processed", value: "0")
                StatTile(label: "Tasks extracted", value: "0")
                StatTile(label: "Cost so far", value: "$0.00")
            }
        }
    }
}

private struct StatTile: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .default))
                .tracking(-0.5)
            Text(label).font(.system(size: 11.5)).foregroundStyle(ToraTokens.text3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ToraTokens.surface2)
        .overlay(
            RoundedRectangle(cornerRadius: 10).stroke(ToraTokens.border, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Customers

private struct CustomersPane: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PaneHeader(
                title: "Customers & Products",
                subtitle: "Tora's AI tags suggestions with the customer and product they relate to. New names auto-create when you accept a suggestion."
            )

            Section {
                ForEach(Array(state.customers.enumerated()), id: \.element.id) { index, customer in
                    SectionRow(divider: index < state.customers.count - 1) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AccentPreset.tora.color.opacity(0.08))
                                    .frame(width: 36, height: 36)
                                Image(systemName: ToraIcon.building).font(.system(size: 18)).foregroundStyle(AccentPreset.tora.color)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(customer.name).font(.system(size: 13, weight: .semibold))
                                Text("\(customer.taskCount) active tasks")
                                    .font(.system(size: 11.5))
                                    .foregroundStyle(ToraTokens.text3)
                            }
                        }
                    } trailing: {
                        Button {} label: {
                            Image(systemName: ToraIcon.external).font(.system(size: 11))
                        }.buttonStyle(.toraGhost)
                    }
                }
            }

            Button {} label: {
                HStack(spacing: 6) {
                    Image(systemName: ToraIcon.plus).font(.system(size: 11))
                    Text("Add customer")
                }
            }.buttonStyle(.toraSecondary)
        }
    }
}

// MARK: - Shortcuts

private struct ShortcutsPane: View {
    private let shortcuts: [(String, [String])] = [
        ("Toggle popover", ["⌘", "⇧", "T"]),
        ("Accept suggestion", ["⌘", "↵"]),
        ("Dismiss suggestion", ["⌘", "⌫"]),
        ("Quick add task", ["⌘", "N"]),
        ("Navigate suggestions", ["↑", "↓"]),
        ("Open task list", ["⌘", "L"]),
        ("Mark complete", ["⌘", "D"]),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PaneHeader(
                title: "Keyboard Shortcuts",
                subtitle: "Tora is keyboard-first. Remappable in Wave 5."
            )
            Section {
                ForEach(Array(shortcuts.enumerated()), id: \.offset) { index, item in
                    SectionRow(divider: index < shortcuts.count - 1) {
                        Text(item.0).font(.system(size: 13))
                    } trailing: {
                        HStack(spacing: 3) {
                            ForEach(item.1, id: \.self) { key in
                                KbdView(key: key)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Notifications

private struct NotificationsPane: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PaneHeader(
                title: "Notifications",
                subtitle: "Calm by default — high-urgency only."
            )
            Section {
                ToggleRow(title: "High urgency", subtitle: "Banner + sound", initialValue: true)
                ToggleRow(title: "Medium urgency", subtitle: "Silent notification", initialValue: true)
                ToggleRow(title: "Low urgency", subtitle: "Badge only", initialValue: true, divider: false)
            }
        }
    }
}
