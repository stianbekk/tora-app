import SwiftUI

struct TaskListView: View {
    @Environment(AppState.self) private var state
    @State private var searchText: String = ""

    var body: some View {
        HSplitView {
            sidebar
                .frame(minWidth: 220, idealWidth: 220, maxWidth: 280)
            mainPane
                .frame(minWidth: 480)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: Sidebar

    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 1) {
                sidebarItem(.inbox, icon: ToraIcon.inbox, count: state.pendingCount)
                sidebarItem(.today, icon: ToraIcon.bolt, count: tasks(for: .today).count)
                sidebarItem(.allOpen, icon: ToraIcon.list, count: state.openTaskCount)
                sidebarItem(.completed, icon: ToraIcon.check, count: state.completedTodayCount)

                Text("CUSTOMERS").uppercaseSectionStyle()
                    .padding(.horizontal, 10)
                    .padding(.top, 14)
                    .padding(.bottom, 5)

                ForEach(state.customers) { customer in
                    sidebarItem(.customer(customer.name), icon: ToraIcon.building, count: customer.taskCount)
                }

                Text("PRODUCTS").uppercaseSectionStyle()
                    .padding(.horizontal, 10)
                    .padding(.top, 14)
                    .padding(.bottom, 5)

                ForEach(state.products) { product in
                    sidebarItem(.product(product.name), icon: ToraIcon.tag, count: product.taskCount)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
        }
        .background(ToraTokens.surface2)
    }

    @ViewBuilder
    private func sidebarItem(_ filter: SidebarFilter, icon: String, count: Int) -> some View {
        let active = state.sidebarFilter == filter
        Button {
            state.sidebarFilter = filter
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .frame(width: 14)
                Text(label(for: filter))
                    .font(.system(size: 12.5, weight: active ? .semibold : .medium))
                Spacer(minLength: 0)
                Text("\(count)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(active ? Color.accent : ToraTokens.text4)
            }
            .foregroundStyle(active ? Color.accent : ToraTokens.text2)
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(active ? Color.accent.opacity(0.13) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func label(for filter: SidebarFilter) -> String {
        switch filter {
        case .inbox: return "Inbox"
        case .today: return "Today"
        case .allOpen: return "All open"
        case .completed: return "Completed"
        case .customer(let n): return n
        case .product(let n): return n
        }
    }

    // MARK: Main pane

    private var mainPane: some View {
        VStack(spacing: 0) {
            header
            Divider().background(ToraTokens.borderSoft)
            if case .inbox = state.sidebarFilter {
                inboxList
            } else {
                taskList
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(state.sidebarFilter.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .tracking(-0.3)
                    Text("\(currentCount)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(ToraTokens.text4)
                }
                if let sub = state.sidebarFilter.subtitle {
                    Text(sub).font(.system(size: 11.5)).foregroundStyle(ToraTokens.text3)
                }
            }
            Spacer()
            if case .inbox = state.sidebarFilter {
                EmptyView()
            } else {
                Button {} label: {
                    HStack(spacing: 6) {
                        Image(systemName: ToraIcon.filter).font(.system(size: 11))
                        Text("Filter")
                    }
                }.buttonStyle(.toraGhost)
                Button {} label: {
                    HStack(spacing: 6) {
                        Image(systemName: ToraIcon.sort).font(.system(size: 11))
                        Text("Sort")
                    }
                }.buttonStyle(.toraGhost)
                Button {} label: {
                    HStack(spacing: 6) {
                        Image(systemName: ToraIcon.plus).font(.system(size: 11))
                        Text("New")
                    }
                }.buttonStyle(.toraPrimary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var currentCount: Int {
        if case .inbox = state.sidebarFilter { return state.pendingCount }
        return tasks(for: state.sidebarFilter).count
    }

    // MARK: Inbox list

    private var inboxList: some View {
        ScrollView {
            VStack(spacing: 10) {
                if state.suggestions.isEmpty {
                    Text("Inbox zero — nothing to triage.")
                        .font(.system(size: 13))
                        .foregroundStyle(ToraTokens.text3)
                        .padding(.vertical, 60)
                } else {
                    ForEach(state.suggestions) { suggestion in
                        if state.inlineEditId == suggestion.id {
                            InlineAcceptEditor(
                                suggestion: suggestion,
                                customers: state.customerNames,
                                products: state.productNames,
                                onConfirm: { edits in state.accept(suggestionId: suggestion.id, edits: edits) },
                                onCancel: { state.inlineEditId = nil }
                            )
                        } else {
                            SuggestionCardView(
                                suggestion: suggestion,
                                isFocused: state.focusedSuggestionId == suggestion.id,
                                onAccept: { state.inlineEditId = suggestion.id },
                                onDismiss: { state.dismiss(suggestionId: suggestion.id) },
                                onTap: {
                                    state.focusedSuggestionId = suggestion.id
                                    state.inlineEditId = suggestion.id
                                }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: 600, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Task list

    private var taskList: some View {
        let filtered = tasks(for: state.sidebarFilter)
        let open = filtered.filter { !$0.completed }
        let done = filtered.filter { $0.completed }

        return ScrollView {
            LazyVStack(spacing: 0) {
                if open.isEmpty && done.isEmpty {
                    Text("No tasks here.")
                        .font(.system(size: 13))
                        .foregroundStyle(ToraTokens.text3)
                        .padding(.vertical, 60)
                }
                ForEach(open) { task in
                    TaskRowView(task: task,
                                selected: state.selectedTaskId == task.id,
                                onSelect: { state.selectedTaskId = task.id },
                                onToggle: { state.toggleComplete(taskId: task.id) })
                }
                if !done.isEmpty {
                    Text("COMPLETED (\(done.count))")
                        .uppercaseSectionStyle()
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .padding(.bottom, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(done) { task in
                        TaskRowView(task: task,
                                    selected: state.selectedTaskId == task.id,
                                    onSelect: { state.selectedTaskId = task.id },
                                    onToggle: { state.toggleComplete(taskId: task.id) })
                    }
                }
            }
        }
    }

    // MARK: Filtering

    private func tasks(for filter: SidebarFilter) -> [TaskViewModel] {
        switch filter {
        case .inbox:    return []
        case .today:    return state.tasks.filter { !$0.completed && $0.due == "Today" }
        case .allOpen:  return state.tasks.filter { !$0.completed }
        case .completed: return state.tasks.filter { $0.completed }
        case .customer(let n): return state.tasks.filter { $0.customer == n }
        case .product(let n): return state.tasks.filter { $0.product == n }
        }
    }
}

// MARK: - Task row

struct TaskRowView: View {
    @Environment(\.toraAccent) private var accent

    let task: TaskViewModel
    let selected: Bool
    let onSelect: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: task.completed ? ToraIcon.checkCircle : ToraIcon.circle)
                    .font(.system(size: 16))
                    .foregroundStyle(task.completed ? accent : ToraTokens.text4)
            }
            .buttonStyle(.plain)
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(task.completed ? ToraTokens.text4 : ToraTokens.text)
                    .strikethrough(task.completed, color: ToraTokens.text4)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if let due = task.due {
                        HStack(spacing: 3) {
                            Image(systemName: ToraIcon.clock).font(.system(size: 10))
                            Text(due)
                        }
                        .foregroundStyle(due == "Today" && !task.completed ? accent : ToraTokens.text3)
                    }
                    if let customer = task.customer {
                        Circle().fill(ToraTokens.text4).frame(width: 3, height: 3)
                        HStack(spacing: 3) {
                            Image(systemName: ToraIcon.building).font(.system(size: 10))
                            Text(customer)
                        }
                        .foregroundStyle(ToraTokens.text3)
                    }
                    if let product = task.product {
                        Circle().fill(ToraTokens.text4).frame(width: 3, height: 3)
                        HStack(spacing: 3) {
                            Image(systemName: ToraIcon.tag).font(.system(size: 10))
                            Text(product)
                        }
                        .foregroundStyle(ToraTokens.text3)
                    }
                    Spacer(minLength: 0)
                    if task.completed, let completedAt = task.completedAt {
                        Text(completedAt)
                            .font(.system(size: 11))
                            .foregroundStyle(ToraTokens.text4)
                    }
                }
                .font(.system(size: 11.5))
            }

            Circle()
                .fill(priorityColor)
                .frame(width: 4, height: 4)
                .opacity(task.completed ? 0.3 : 1)
                .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .frame(minHeight: 38, alignment: .top)
        .background(
            Rectangle()
                .fill(selected ? accent.opacity(0.13) : Color.clear)
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(selected ? accent : Color.clear)
                .frame(width: 2)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }

    private var priorityColor: Color {
        switch task.priority {
        case .high: return accent
        case .medium: return ToraTokens.text3
        case .low: return ToraTokens.text4
        }
    }
}

// MARK: - Color shortcut for the sidebar

private extension Color {
    static var accent: Color { AccentPreset.tora.color }
}
