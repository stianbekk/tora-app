import SwiftUI

enum FirstRunStep: Int, CaseIterable {
    case welcome
    case apiKey
    case slack
    case permissions

    var label: String {
        switch self {
        case .welcome:     return "Welcome"
        case .apiKey:      return "API key"
        case .slack:       return "Connect Slack"
        case .permissions: return "Permissions"
        }
    }
}

struct FirstRunView: View {
    @State private var step: FirstRunStep = .welcome
    @State private var apiKey: String = ""
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            progressBar
            ScrollView { stepContent }
                .padding(.horizontal, 56)
                .padding(.vertical, 32)
            footer
        }
        .background(.ultraThinMaterial)
    }

    // MARK: Progress bar

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(FirstRunStep.allCases, id: \.rawValue) { s in
                Capsule()
                    .fill(s.rawValue <= step.rawValue ? AccentPreset.tora.color : ToraTokens.surface3)
                    .frame(height: 3)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
    }

    // MARK: Step content

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome: WelcomeStep()
        case .apiKey:  ApiKeyStep(apiKey: $apiKey)
        case .slack:   ConnectSlackStep()
        case .permissions: PermissionsStep()
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 8) {
            Text("Step \(step.rawValue + 1) of \(FirstRunStep.allCases.count) · \(step.label)")
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundStyle(ToraTokens.text4)
            Spacer()
            if step.rawValue > 0 {
                Button("Back") {
                    if let prev = FirstRunStep(rawValue: step.rawValue - 1) {
                        step = prev
                    }
                }
                .buttonStyle(.toraSecondary)
            }
            Button {
                if step == .permissions {
                    onDone()
                } else if let next = FirstRunStep(rawValue: step.rawValue + 1) {
                    step = next
                }
            } label: {
                HStack(spacing: 6) {
                    Text(step == .permissions ? "Open Tora" : "Continue")
                    Image(systemName: ToraIcon.arrow).font(.system(size: 11))
                }
            }
            .buttonStyle(.toraPrimary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(ToraTokens.surface2)
        .overlay(alignment: .top) { Divider().background(ToraTokens.border) }
    }
}

// MARK: - Welcome

private struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 14) {
            Image("Mascot")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .shadow(color: AccentPreset.tora.color.opacity(0.35), radius: 18, y: 6)

            Text("Hi, I'm Tora")
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.6)

            Text("A quiet menu bar assistant that watches your Slack and Gmail, finds the actionable bits, and keeps them in one place. Set up takes about a minute.")
                .font(.system(size: 14))
                .foregroundStyle(ToraTokens.text3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520)

            HStack(alignment: .top, spacing: 10) {
                ValueProp(icon: ToraIcon.bolt, title: "Local-first",
                          description: "Raw messages never stored. Only extracted task metadata, in SQLite on your Mac.")
                ValueProp(icon: ToraIcon.inbox, title: "No mentions needed",
                          description: "AI decides what's actionable for you. Important asks rarely come with @ tags.")
                ValueProp(icon: ToraIcon.check, title: "Stay in flow",
                          description: "Lives in the menu bar. ⌘⇧T to peek, ⌘↵ to accept. Never breaks your focus.")
            }
            .padding(.top, 18)
        }
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
    }
}

private struct ValueProp: View {
    let icon: String
    let title: String
    let description: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(AccentPreset.tora.color.opacity(0.13))
                    .frame(width: 28, height: 28)
                Image(systemName: icon).font(.system(size: 14)).foregroundStyle(AccentPreset.tora.color)
            }
            Text(title).font(.system(size: 12.5, weight: .semibold))
            Text(description)
                .font(.system(size: 11.5))
                .foregroundStyle(ToraTokens.text3)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ToraTokens.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ToraTokens.border, lineWidth: 0.5))
    }
}

// MARK: - API Key

private struct ApiKeyStep: View {
    @Binding var apiKey: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Connect OpenAI").font(.system(size: 22, weight: .bold)).tracking(-0.4)
            Text("Tora uses GPT-5.4-mini with structured outputs to extract tasks. About **$5/month** for typical use. Your key is stored in macOS Keychain and never leaves your machine.")
                .font(.system(size: 13))
                .foregroundStyle(ToraTokens.text3)

            VStack(alignment: .leading, spacing: 8) {
                Text("OPENAI API KEY").uppercaseSectionStyle()
                HStack(spacing: 6) {
                    TextField("sk-proj-...", text: $apiKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12.5, design: .monospaced))
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(ToraTokens.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(ToraTokens.borderStrong, lineWidth: 0.5))
                    Button("Paste") {
                        if let s = NSPasteboard.general.string(forType: .string) {
                            apiKey = s
                        }
                    }
                    .buttonStyle(.toraSecondary)
                }
                Link(destination: URL(string: "https://platform.openai.com/api-keys")!) {
                    HStack(spacing: 6) {
                        Image(systemName: ToraIcon.external).font(.system(size: 11))
                        Text("Get an API key from platform.openai.com")
                    }
                    .font(.system(size: 11.5))
                    .foregroundStyle(ToraTokens.text3)
                }
            }
            .padding(14)
            .background(ToraTokens.surface2)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(ToraTokens.border, lineWidth: 0.5))

            Text("**Privacy note:** Tora sends each message to OpenAI for extraction. If your workplace forbids that, use the local model option (Ollama) coming in v2.")
                .font(.system(size: 11.5))
                .foregroundStyle(ToraTokens.text2)
                .padding(12)
                .background(AccentPreset.tora.color.opacity(0.13))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: 520, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Connect Slack

private struct ConnectSlackStep: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Connect Slack").font(.system(size: 22, weight: .bold)).tracking(-0.4)
            Text("Tora installs as a Slack app in your workspace. It needs read access to channels you choose so it can spot actionable messages. You can change selected channels any time.")
                .font(.system(size: 13))
                .foregroundStyle(ToraTokens.text3)

            VStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color(red: 0.29, green: 0.08, blue: 0.29))
                        .frame(width: 52, height: 52)
                    Image(systemName: ToraIcon.slack).font(.system(size: 26)).foregroundStyle(.white)
                }
                Text("Add Tora to your workspace").font(.system(size: 14, weight: .semibold))
                Text("Opens slack.com in your browser").font(.system(size: 11.5)).foregroundStyle(ToraTokens.text3)
                Button {} label: {
                    HStack(spacing: 6) {
                        Image(systemName: ToraIcon.slack).font(.system(size: 13))
                        Text("Add to Slack")
                    }
                }
                .buttonStyle(.toraPrimary)
            }
            .padding(22)
            .frame(maxWidth: .infinity)
            .background(ToraTokens.surface2)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ToraTokens.border, lineWidth: 0.5))

            Text("REQUIRED SCOPES").uppercaseSectionStyle().padding(.top, 6)

            VStack(spacing: 0) {
                scopeRow("channels:history", "Read public channel messages", divider: true)
                scopeRow("groups:history", "Read private channel messages", divider: true)
                scopeRow("im:history", "Read direct messages", divider: true)
                scopeRow("users:read", "Resolve user names", divider: false)
            }
            .background(ToraTokens.surface2)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(ToraTokens.border, lineWidth: 0.5))
        }
        .frame(maxWidth: 520, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func scopeRow(_ scope: String, _ desc: String, divider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: ToraIcon.check).font(.system(size: 13)).foregroundStyle(AccentPreset.tora.color)
                Text(scope).font(.system(size: 11.5, design: .monospaced)).foregroundStyle(ToraTokens.text)
                Spacer()
                Text(desc).font(.system(size: 11.5)).foregroundStyle(ToraTokens.text3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            if divider { Divider().background(ToraTokens.border) }
        }
    }
}

// MARK: - Permissions

private struct PermissionsStep: View {
    private struct Row { let icon: String; let title: String; let desc: String; let granted: Bool }
    private let rows: [Row] = [
        .init(icon: ToraIcon.bell, title: "Notifications", desc: "For high-urgency suggestions", granted: false),
        .init(icon: ToraIcon.inbox, title: "Network access", desc: "Local relay server on port 9377", granted: true),
        .init(icon: ToraIcon.bolt, title: "Launch at login", desc: "Start when you log in to your Mac", granted: false),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("macOS permissions").font(.system(size: 22, weight: .bold)).tracking(-0.4)
            Text("A couple of system prompts to grant. You can revoke any of these in System Settings.")
                .font(.system(size: 13))
                .foregroundStyle(ToraTokens.text3)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(ToraTokens.surface3)
                                .frame(width: 32, height: 32)
                            Image(systemName: row.icon).font(.system(size: 14)).foregroundStyle(ToraTokens.text2)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.title).font(.system(size: 13, weight: .semibold))
                            Text(row.desc).font(.system(size: 11.5)).foregroundStyle(ToraTokens.text3)
                        }
                        Spacer()
                        if row.granted {
                            HStack(spacing: 5) {
                                Image(systemName: ToraIcon.check).font(.system(size: 12)).foregroundStyle(.green)
                                Text("Granted").font(.system(size: 11.5, weight: .semibold)).foregroundStyle(.green)
                            }
                        } else {
                            Button("Allow") {}.buttonStyle(.toraSecondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    if index < rows.count - 1 { Divider().background(ToraTokens.border) }
                }
            }
            .background(ToraTokens.surface2)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(ToraTokens.border, lineWidth: 0.5))
        }
        .frame(maxWidth: 520, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
