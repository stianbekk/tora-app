import SwiftUI

struct NewTaskSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var customer: String = ""
    @State private var product: String = ""
    @State private var priority: ToraTask.Priority = .medium
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("New task").font(.system(size: 18, weight: .bold)).tracking(-0.3)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: ToraIcon.xmark).font(.system(size: 12))
                }
                .buttonStyle(.toraGhost)
                .keyboardShortcut(.cancelAction)
            }

            TextField("What needs to happen?", text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(ToraTokens.surface2)
                .clipShape(RoundedRectangle(cornerRadius: 7))

            HStack(spacing: 8) {
                Menu {
                    Button("None") { customer = "" }
                    Divider()
                    ForEach(state.customers) { c in
                        Button(c.name) { customer = c.name }
                    }
                } label: {
                    LabelChip(icon: ToraIcon.building, label: customer.isEmpty ? "Customer" : customer)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)

                Menu {
                    Button("None") { product = "" }
                    Divider()
                    ForEach(state.products) { p in
                        Button(p.name) { product = p.name }
                    }
                } label: {
                    LabelChip(icon: ToraIcon.tag, label: product.isEmpty ? "Product" : product)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)

                Menu {
                    ForEach(ToraTask.Priority.allCases, id: \.self) { p in
                        Button(p.displayName) { priority = p }
                    }
                } label: {
                    LabelChip(icon: ToraIcon.flag, label: priority.displayName)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)

                Spacer()
            }

            HStack(spacing: 8) {
                Toggle(isOn: $hasDueDate) {
                    Text("Due date").font(.system(size: 12, weight: .medium))
                }
                .toggleStyle(.checkbox)
                if hasDueDate {
                    DatePicker("", selection: $dueDate, displayedComponents: [.date])
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }
                Spacer()
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.toraSecondary)
                Button {
                    state.createManualTask(
                        title: title,
                        customer: customer.isEmpty ? nil : customer,
                        product: product.isEmpty ? nil : product,
                        due: hasDueDate ? dueDate : nil,
                        priority: priority
                    )
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: ToraIcon.check).font(.system(size: 11))
                        Text("Add task")
                    }
                }
                .buttonStyle(.toraPrimary)
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 520)
    }
}

private struct LabelChip: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 11))
            Text(label).font(.system(size: 12, weight: .medium))
            Image(systemName: ToraIcon.chevDown).font(.system(size: 9))
        }
        .foregroundStyle(ToraTokens.text2)
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(ToraTokens.surface3)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(ToraTokens.borderSoft, lineWidth: 0.5))
    }
}
