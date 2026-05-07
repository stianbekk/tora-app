import SwiftUI

// MARK: - Inline editor shown when accepting a suggestion as a task

struct InlineAcceptEdits: Equatable {
    var title: String
    var customer: String
    var product: String
    var due: String
    var priority: ToraTask.Priority
}

struct InlineAcceptEditor: View {
    @Environment(\.toraAccent) private var accent

    let suggestion: SuggestionViewModel
    let customers: [String]
    let products: [String]
    let onConfirm: (InlineAcceptEdits) -> Void
    let onCancel: () -> Void

    @State private var title: String
    @State private var customer: String
    @State private var product: String
    @State private var due: String
    @State private var priority: ToraTask.Priority

    init(
        suggestion: SuggestionViewModel,
        customers: [String],
        products: [String],
        onConfirm: @escaping (InlineAcceptEdits) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.suggestion = suggestion
        self.customers = customers
        self.products = products
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        _title    = State(initialValue: suggestion.title)
        _customer = State(initialValue: suggestion.customer ?? "")
        _product  = State(initialValue: suggestion.product ?? "")
        _due      = State(initialValue: suggestion.due ?? "")
        _priority = State(initialValue: ToraTask.Priority(urgency: suggestion.urgency))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ACCEPT AS TASK")
                .font(ToraFont.sectionHeader)
                .tracking(0.6)
                .foregroundStyle(accent)

            TextField("Task title", text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ToraTokens.text)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6).fill(ToraTokens.surface2)
                )

            HStack(spacing: 6) {
                EditField(
                    label: "CUSTOMER",
                    icon: ToraIcon.building,
                    value: $customer,
                    options: customers
                )
                EditField(
                    label: "PRODUCT",
                    icon: ToraIcon.tag,
                    value: $product,
                    options: products
                )
            }

            HStack(spacing: 6) {
                EditField(
                    label: "DUE",
                    icon: ToraIcon.clock,
                    value: $due,
                    options: ["Today", "Tomorrow", "This week", "Next week"]
                )
                EditPriorityField(priority: $priority)
            }
            .padding(.bottom, 2)

            HStack(spacing: 6) {
                Button(action: confirm) {
                    HStack(spacing: 6) {
                        Image(systemName: ToraIcon.check).font(.system(size: 11))
                        Text("Save task")
                    }
                }
                .buttonStyle(.toraPrimary)
                .keyboardShortcut(.defaultAction)

                Button("Cancel", action: onCancel)
                    .buttonStyle(.toraSecondary)
                    .keyboardShortcut(.cancelAction)

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    KbdView(key: "↵")
                    Text("save")
                        .font(.system(size: 10.5))
                        .foregroundStyle(ToraTokens.text4)
                }
            }
        }
        .padding(12)
        .glassCard()
        .focusRing(true)
    }

    private func confirm() {
        onConfirm(InlineAcceptEdits(
            title: title,
            customer: customer,
            product: product,
            due: due,
            priority: priority
        ))
    }
}

// MARK: - Field components

private struct EditField: View {
    let label: String
    let icon: String
    @Binding var value: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 9.5, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(ToraTokens.text4)

            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) { value = option }
                }
                Divider()
                Button("Clear") { value = "" }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                        .foregroundStyle(ToraTokens.text3)
                    Text(value.isEmpty ? "—" : value)
                        .font(.system(size: 11.5))
                        .foregroundStyle(value.isEmpty ? ToraTokens.text4 : ToraTokens.text)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: ToraIcon.chevDown)
                        .font(.system(size: 9))
                        .foregroundStyle(ToraTokens.text4)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 6).fill(ToraTokens.surface2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6).stroke(ToraTokens.border, lineWidth: 0.5)
                )
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
        }
    }
}

private struct EditPriorityField: View {
    @Binding var priority: ToraTask.Priority

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("PRIORITY")
                .font(.system(size: 9.5, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(ToraTokens.text4)

            Menu {
                ForEach(ToraTask.Priority.allCases, id: \.self) { p in
                    Button(p.displayName) { priority = p }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: ToraIcon.flag)
                        .font(.system(size: 10))
                        .foregroundStyle(ToraTokens.text3)
                    Text(priority.displayName)
                        .font(.system(size: 11.5))
                        .foregroundStyle(ToraTokens.text)
                    Spacer(minLength: 0)
                    Image(systemName: ToraIcon.chevDown)
                        .font(.system(size: 9))
                        .foregroundStyle(ToraTokens.text4)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 6).fill(ToraTokens.surface2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6).stroke(ToraTokens.border, lineWidth: 0.5)
                )
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
        }
    }
}

// MARK: - Helpers

extension ToraTask.Priority {
    init(urgency: Suggestion.Urgency) {
        switch urgency {
        case .high:   self = .high
        case .medium: self = .medium
        case .low:    self = .low
        }
    }

    var displayName: String {
        switch self {
        case .high:   return "High"
        case .medium: return "Medium"
        case .low:    return "Low"
        }
    }
}
