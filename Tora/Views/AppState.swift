import Foundation
import SwiftUI
import Observation

// MARK: - Sample data for previews / first-launch demo state

enum SampleData {
    static let suggestions: [SuggestionViewModel] = [
        .init(
            id: "s1", source: .slack, sourceLabel: "DM", person: "Frank Halvorsen",
            title: "Send updated pricing doc to Megaflis",
            snippet: "\"Hey, can you send over the updated pricing doc when you get a chance? Need it for the board meeting Thursday.\"",
            urgency: .high, due: "Today", customer: "Megaflis", product: nil,
            receivedAt: "2 min ago"
        ),
        .init(
            id: "s2", source: .slack, sourceLabel: "#dev", person: "Eirik Sandvik",
            title: "Review PR #142 before Friday deploy",
            snippet: "\"PR is ready for review — touches the ticket dedup logic, would love your eyes before we ship Friday.\"",
            urgency: .medium, due: "Fri, May 9", customer: "Megaflis", product: "Ticket Agent",
            receivedAt: "14 min ago"
        ),
        .init(
            id: "s3", source: .gmail, sourceLabel: "Inbox", person: "Lise Bjørnstad",
            title: "Schedule onboarding call with VPG team",
            snippet: "\"Looking forward to getting started. Can we book a 30-min onboarding next week? Tuesday or Wednesday afternoon works on our side.\"",
            urgency: .medium, due: "Next week", customer: "VPG", product: "Shop Assistant",
            receivedAt: "38 min ago"
        ),
    ]

    static let tasks: [TaskViewModel] = [
        .init(id: "t1", title: "Draft Q2 board update for Megaflis",
              customer: "Megaflis", product: nil, priority: .high,
              due: "Tomorrow", completed: false, completedAt: nil),
        .init(id: "t2", title: "Review Ticket Agent dedup spec",
              customer: "Megaflis", product: "Ticket Agent", priority: .medium,
              due: "Today", completed: false, completedAt: nil),
        .init(id: "t3", title: "Reply to VPG procurement contract redlines",
              customer: "VPG", product: "Shop Assistant", priority: .high,
              due: "Today", completed: false, completedAt: nil),
        .init(id: "t4", title: "Update Stripe pricing tiers in admin",
              customer: nil, product: nil, priority: .low,
              due: "This week", completed: false, completedAt: nil),
        .init(id: "t5", title: "Send Megaflis renewal proposal",
              customer: "Megaflis", product: nil, priority: .medium,
              due: "Mon, May 12", completed: false, completedAt: nil),
        .init(id: "t8", title: "Reply to Frank re: SOC2 timeline",
              customer: "Megaflis", product: nil, priority: .medium,
              due: "Today", completed: true, completedAt: "9:14 AM"),
        .init(id: "t9", title: "Merge GRDB upgrade branch",
              customer: nil, product: "Ticket Agent", priority: .medium,
              due: "Today", completed: true, completedAt: "8:32 AM"),
    ]

    static let customers: [CustomerViewModel] = [
        .init(id: "c1", name: "Megaflis", taskCount: 4),
        .init(id: "c2", name: "VPG", taskCount: 2),
    ]

    static let products: [ProductViewModel] = [
        .init(id: "p1", name: "Ticket Agent", taskCount: 3),
        .init(id: "p2", name: "Shop Assistant", taskCount: 1),
    ]
}

// MARK: - View models

struct TaskViewModel: Identifiable, Hashable {
    let id: String
    var title: String
    var customer: String?
    var product: String?
    var priority: ToraTask.Priority
    var due: String?
    var completed: Bool
    var completedAt: String?
}

struct CustomerViewModel: Identifiable, Hashable {
    let id: String
    let name: String
    let taskCount: Int
}

struct ProductViewModel: Identifiable, Hashable {
    let id: String
    let name: String
    let taskCount: Int
}

// MARK: - Filter

enum SidebarFilter: Hashable {
    case inbox
    case today
    case allOpen
    case completed
    case customer(String)
    case product(String)

    var displayName: String {
        switch self {
        case .inbox: return "Inbox"
        case .today: return "Today"
        case .allOpen: return "All open tasks"
        case .completed: return "Completed"
        case .customer(let name): return name
        case .product(let name): return name
        }
    }

    var subtitle: String? {
        if case .inbox = self {
            return "AI-extracted suggestions awaiting your decision"
        }
        return nil
    }
}

// MARK: - App state

/// Central observable state used by popover, task list, settings, and toast.
/// Wave 4 will replace the in-memory arrays with live GRDB observation.
@Observable
@MainActor
final class AppState {
    var suggestions: [SuggestionViewModel]
    var tasks: [TaskViewModel]
    var customers: [CustomerViewModel]
    var products: [ProductViewModel]

    var focusedSuggestionId: String?
    var inlineEditId: String?
    var selectedTaskId: String?
    var sidebarFilter: SidebarFilter = .inbox

    var accent: AccentPreset = .tora
    var glyphVariant: GlyphView.Variant = .mascot
    var appearance: AppearanceMode = .system

    init(
        suggestions: [SuggestionViewModel] = SampleData.suggestions,
        tasks: [TaskViewModel] = SampleData.tasks,
        customers: [CustomerViewModel] = SampleData.customers,
        products: [ProductViewModel] = SampleData.products
    ) {
        self.suggestions = suggestions
        self.tasks = tasks
        self.customers = customers
        self.products = products
        self.focusedSuggestionId = suggestions.first?.id
    }

    // MARK: - Mutations

    func accept(suggestionId: String, edits: InlineAcceptEdits? = nil) {
        guard let idx = suggestions.firstIndex(where: { $0.id == suggestionId }) else { return }
        let s = suggestions[idx]
        let task = TaskViewModel(
            id: "t-\(s.id)",
            title: edits?.title ?? s.title,
            customer: (edits?.customer.isEmpty == false ? edits?.customer : s.customer),
            product: (edits?.product.isEmpty == false ? edits?.product : s.product),
            priority: edits?.priority ?? ToraTask.Priority(urgency: s.urgency),
            due: (edits?.due.isEmpty == false ? edits?.due : s.due),
            completed: false,
            completedAt: nil
        )
        tasks.insert(task, at: 0)
        suggestions.remove(at: idx)
        inlineEditId = nil
        focusedSuggestionId = suggestions.first?.id
    }

    func dismiss(suggestionId: String) {
        suggestions.removeAll { $0.id == suggestionId }
        if focusedSuggestionId == suggestionId {
            focusedSuggestionId = suggestions.first?.id
        }
    }

    func toggleComplete(taskId: String) {
        guard let idx = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        tasks[idx].completed.toggle()
        tasks[idx].completedAt = tasks[idx].completed ? "just now" : nil
    }

    var pendingCount: Int { suggestions.count }
    var openTaskCount: Int { tasks.filter { !$0.completed }.count }
    var completedTodayCount: Int { tasks.filter { $0.completed }.count }
    var customerNames: [String] { customers.map(\.name) }
    var productNames: [String] { products.map(\.name) }
}

// MARK: - Appearance mode

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .system: return "Match system"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
