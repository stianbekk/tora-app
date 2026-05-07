import Foundation
import SwiftUI
import Observation

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

// MARK: - Appearance

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

// MARK: - App state

/// Central observable state. Reads from GRDB on demand and refreshes via `reload()`
/// after any mutation. Wave 5 will replace explicit refresh with ValueObservation.
@Observable
@MainActor
final class AppState {
    // MARK: Published state

    var suggestions: [SuggestionViewModel] = []
    var tasks: [TaskViewModel] = []
    var customers: [CustomerViewModel] = []
    var products: [ProductViewModel] = []

    var focusedSuggestionId: String?
    var inlineEditId: String?
    var selectedTaskId: String?
    var sidebarFilter: SidebarFilter = .inbox

    var accent: AccentPreset = .tora
    var glyphVariant: GlyphView.Variant = .mascot
    var appearance: AppearanceMode = .system

    /// Queued toast — popped by the menu bar host when ready.
    var pendingToast: SuggestionViewModel?

    // MARK: Dependencies

    private let suggestionsRepo: SuggestionRepository
    private let tasksRepo: TaskRepository
    private let customersRepo: CustomerRepository
    private let productsRepo: ProductRepository
    private let sourcesRepo: SourceRepository
    private let settingsRepo: SettingsRepository

    init(
        suggestions: SuggestionRepository = SuggestionRepository(),
        tasks: TaskRepository = TaskRepository(),
        customers: CustomerRepository = CustomerRepository(),
        products: ProductRepository = ProductRepository(),
        sources: SourceRepository = SourceRepository(),
        settings: SettingsRepository = SettingsRepository()
    ) {
        self.suggestionsRepo = suggestions
        self.tasksRepo = tasks
        self.customersRepo = customers
        self.productsRepo = products
        self.sourcesRepo = sources
        self.settingsRepo = settings
    }

    // MARK: - Bootstrap

    func bootstrap() {
        seedIfNeeded()
        reload()
    }

    /// Re-fetch everything from the database. Cheap because all tables are tiny.
    func reload() {
        do {
            let allCustomers = try customersRepo.all()
            let allProducts = try productsRepo.all()

            let pendingSuggestions = try suggestionsRepo.pending()
            let allTasks = try tasksRepo.allOpen() + tasksRepo.completedToday()

            self.suggestions = pendingSuggestions.map {
                SuggestionViewModel($0, customers: allCustomers, products: allProducts)
            }
            self.tasks = allTasks.map {
                TaskViewModel($0, customers: allCustomers, products: allProducts)
            }
            self.customers = allCustomers.map { c in
                let count = (try? tasksRepo.forCustomer(c.id).filter { !$0.completed }.count) ?? 0
                return CustomerViewModel(id: c.id, name: c.name, taskCount: count)
            }
            self.products = allProducts.map { p in
                let count = (try? tasksRepo.forProduct(p.id).filter { !$0.completed }.count) ?? 0
                return ProductViewModel(id: p.id, name: p.name, taskCount: count)
            }

            if focusedSuggestionId == nil || !pendingSuggestions.contains(where: { $0.id == focusedSuggestionId }) {
                focusedSuggestionId = pendingSuggestions.first?.id
            }
        } catch {
            print("AppState reload failed: \(error)")
        }
    }

    /// Convenience for pipeline callers from background actors.
    func reloadFromBackground() {
        // Already MainActor-isolated; this is a clarity helper.
        reload()
    }

    // MARK: - Mutations

    func accept(suggestionId: String, edits: InlineAcceptEdits? = nil) {
        do {
            guard var suggestion = try suggestionsRepo.find(id: suggestionId) else { return }

            // Resolve customer/product (auto-create if needed)
            let resolvedCustomerId = try resolveOrCreateCustomer(name: edits?.customer)
                ?? suggestion.customerId
            let resolvedProductId = try resolveOrCreateProduct(name: edits?.product)
                ?? suggestion.productId

            let now = Date()
            var task = ToraTask(
                id: UUID().uuidString,
                suggestionId: suggestion.id,
                title: edits?.title ?? suggestion.title,
                notes: nil,
                priority: edits?.priority ?? ToraTask.Priority(urgency: suggestion.urgency),
                dueDate: parseDue(edits?.due) ?? suggestion.suggestedDue,
                customerId: resolvedCustomerId,
                productId: resolvedProductId,
                completed: false,
                completedAt: nil,
                createdAt: now,
                updatedAt: now
            )
            try tasksRepo.save(task)
            _ = task

            suggestion.status = .accepted
            suggestion.actedAt = now
            try suggestionsRepo.save(suggestion)

            inlineEditId = nil
            reload()
        } catch {
            print("accept failed: \(error)")
        }
    }

    func dismiss(suggestionId: String) {
        do {
            guard var suggestion = try suggestionsRepo.find(id: suggestionId) else { return }
            suggestion.status = .dismissed
            suggestion.actedAt = Date()
            try suggestionsRepo.save(suggestion)
            reload()
        } catch {
            print("dismiss failed: \(error)")
        }
    }

    func toggleComplete(taskId: String) {
        do {
            guard var task = try tasksRepo.find(id: taskId) else { return }
            task.completed.toggle()
            task.completedAt = task.completed ? Date() : nil
            try tasksRepo.save(task)
            reload()
        } catch {
            print("toggleComplete failed: \(error)")
        }
    }

    func createManualTask(title: String, customer: String?, product: String?, due: Date?, priority: ToraTask.Priority) {
        do {
            let customerId = try resolveOrCreateCustomer(name: customer)
            let productId  = try resolveOrCreateProduct(name: product)
            let now = Date()
            let task = ToraTask(
                id: UUID().uuidString,
                suggestionId: nil,
                title: title,
                notes: nil,
                priority: priority,
                dueDate: due,
                customerId: customerId,
                productId: productId,
                completed: false,
                completedAt: nil,
                createdAt: now,
                updatedAt: now
            )
            try tasksRepo.save(task)
            reload()
        } catch {
            print("createManualTask failed: \(error)")
        }
    }

    // MARK: - Helpers

    private func resolveOrCreateCustomer(name: String?) throws -> String? {
        guard let name, !name.isEmpty else { return nil }
        if let existing = try customersRepo.findByName(name) {
            return existing.id
        }
        let new = Customer(id: UUID().uuidString, name: name, notes: nil, createdAt: Date())
        try customersRepo.save(new)
        return new.id
    }

    private func resolveOrCreateProduct(name: String?) throws -> String? {
        guard let name, !name.isEmpty else { return nil }
        if let existing = try productsRepo.findByName(name) {
            return existing.id
        }
        let new = Product(id: UUID().uuidString, name: name, customerId: nil, notes: nil, createdAt: Date())
        try productsRepo.save(new)
        return new.id
    }

    private func parseDue(_ string: String?) -> Date? {
        guard let s = string, !s.isEmpty else { return nil }
        let cal = Calendar.current
        switch s {
        case "Today":     return cal.startOfDay(for: Date())
        case "Tomorrow":  return cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date()))
        case "This week": return cal.date(byAdding: .day, value: 7, to: cal.startOfDay(for: Date()))
        case "Next week": return cal.date(byAdding: .day, value: 14, to: cal.startOfDay(for: Date()))
        default:
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.date(from: s)
        }
    }

    // MARK: - Computed

    var pendingCount: Int { suggestions.count }
    var openTaskCount: Int { tasks.filter { !$0.completed }.count }
    var completedTodayCount: Int { tasks.filter { $0.completed }.count }
    var customerNames: [String] { customers.map(\.name) }
    var productNames: [String] { products.map(\.name) }

    // MARK: - Demo seeding

    private func seedIfNeeded() {
        do {
            let already = try settingsRepo.get("seeded_v1") == "true"
            if already { return }

            let now = Date()
            let cal = Calendar.current

            // Customers
            let c1 = Customer(id: UUID().uuidString, name: "Megaflis", notes: nil, createdAt: now)
            let c2 = Customer(id: UUID().uuidString, name: "VPG", notes: nil, createdAt: now)
            try customersRepo.save(c1)
            try customersRepo.save(c2)

            // Products
            let p1 = Product(id: UUID().uuidString, name: "Ticket Agent", customerId: c1.id, notes: nil, createdAt: now)
            let p2 = Product(id: UUID().uuidString, name: "Shop Assistant", customerId: c2.id, notes: nil, createdAt: now)
            try productsRepo.save(p1)
            try productsRepo.save(p2)

            // Source for demo suggestions
            let demoSource = Source(
                id: "demo:slack", type: .slack, label: "Demo Workspace",
                config: nil, active: true, createdAt: now
            )
            try sourcesRepo.save(demoSource)

            // Tasks
            let tasks: [ToraTask] = [
                .init(id: UUID().uuidString, suggestionId: nil,
                      title: "Draft Q2 board update for Megaflis",
                      notes: "Include MRR delta, churn analysis, hiring plan.",
                      priority: .high,
                      dueDate: cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)),
                      customerId: c1.id, productId: nil,
                      completed: false, completedAt: nil, createdAt: now, updatedAt: now),
                .init(id: UUID().uuidString, suggestionId: nil,
                      title: "Review Ticket Agent dedup spec", notes: nil,
                      priority: .medium,
                      dueDate: cal.startOfDay(for: now),
                      customerId: c1.id, productId: p1.id,
                      completed: false, completedAt: nil, createdAt: now, updatedAt: now),
                .init(id: UUID().uuidString, suggestionId: nil,
                      title: "Reply to VPG procurement contract redlines",
                      notes: "Legal flagged §7.2 indemnification clause.",
                      priority: .high,
                      dueDate: cal.startOfDay(for: now),
                      customerId: c2.id, productId: p2.id,
                      completed: false, completedAt: nil, createdAt: now, updatedAt: now),
                .init(id: UUID().uuidString, suggestionId: nil,
                      title: "Update Stripe pricing tiers in admin", notes: nil,
                      priority: .low,
                      dueDate: cal.date(byAdding: .day, value: 3, to: now),
                      customerId: nil, productId: nil,
                      completed: false, completedAt: nil, createdAt: now, updatedAt: now),
                .init(id: UUID().uuidString, suggestionId: nil,
                      title: "Reply to Frank re: SOC2 timeline", notes: nil,
                      priority: .medium,
                      dueDate: cal.startOfDay(for: now),
                      customerId: c1.id, productId: nil,
                      completed: true,
                      completedAt: cal.date(bySettingHour: 9, minute: 14, second: 0, of: now),
                      createdAt: now, updatedAt: now),
            ]
            for t in tasks { try tasksRepo.save(t) }

            // Suggestions
            let suggestions: [Suggestion] = [
                .init(id: UUID().uuidString, sourceId: demoSource.id,
                      title: "Send updated pricing doc to Megaflis",
                      sourcePerson: "Frank Halvorsen", sourceChannel: "DM",
                      urgency: .high,
                      suggestedDue: cal.startOfDay(for: now),
                      contextSnippet: "Frank needs pricing doc for Thursday board meeting.",
                      customerId: c1.id, productId: nil,
                      rawSignalHash: "demo-1", status: .pending,
                      createdAt: now.addingTimeInterval(-120), actedAt: nil),
                .init(id: UUID().uuidString, sourceId: demoSource.id,
                      title: "Review PR #142 before Friday deploy",
                      sourcePerson: "Eirik Sandvik", sourceChannel: "#dev",
                      urgency: .medium,
                      suggestedDue: cal.date(byAdding: .day, value: 2, to: cal.startOfDay(for: now)),
                      contextSnippet: "Touches ticket dedup logic — review before ship.",
                      customerId: c1.id, productId: p1.id,
                      rawSignalHash: "demo-2", status: .pending,
                      createdAt: now.addingTimeInterval(-840), actedAt: nil),
                .init(id: UUID().uuidString, sourceId: demoSource.id,
                      title: "Schedule onboarding call with VPG team",
                      sourcePerson: "Lise Bjørnstad", sourceChannel: "Inbox",
                      urgency: .medium,
                      suggestedDue: cal.date(byAdding: .day, value: 5, to: cal.startOfDay(for: now)),
                      contextSnippet: "VPG team wants 30-min onboarding next Tue or Wed afternoon.",
                      customerId: c2.id, productId: p2.id,
                      rawSignalHash: "demo-3", status: .pending,
                      createdAt: now.addingTimeInterval(-2280), actedAt: nil),
            ]
            for s in suggestions { try suggestionsRepo.save(s) }

            try settingsRepo.set("seeded_v1", value: "true")
        } catch {
            print("Seed failed: \(error)")
        }
    }
}
