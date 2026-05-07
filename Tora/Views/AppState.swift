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

    var accent: AccentPreset = .tora {
        didSet { persistPreferences() }
    }
    var glyphVariant: GlyphView.Variant = .mascot {
        didSet { persistPreferences(); onGlyphChanged?(glyphVariant) }
    }
    var appearance: AppearanceMode = .system {
        didSet { persistPreferences(); onAppearanceChanged?(appearance) }
    }
    var showInDock: Bool = false {
        didSet { persistPreferences(); onShowInDockChanged?(showInDock) }
    }
    var launchAtLogin: Bool = true {
        didSet { persistPreferences(); onLaunchAtLoginChanged?(launchAtLogin) }
    }

    /// Side-effect callbacks installed by AppDelegate. Internal to this module.
    var onGlyphChanged: ((GlyphView.Variant) -> Void)?
    var onAppearanceChanged: ((AppearanceMode) -> Void)?
    var onShowInDockChanged: ((Bool) -> Void)?
    var onLaunchAtLoginChanged: ((Bool) -> Void)?

    /// Queued toast — popped by the menu bar host when ready.
    var pendingToast: SuggestionViewModel?

    /// Used by AppDelegate to decide if the first-run wizard should appear.
    var firstRunComplete: Bool = false

    /// Reflects whether a Slack bot token has been saved. Powers the sources status indicator.
    var slackConnected: Bool = false

    /// Latest backfill status — surfaced as "Catching up…" in the popover.
    var backfillStatus: BackfillStatus = .idle

    // MARK: Dependencies

    private let suggestionsRepo: SuggestionRepository
    private let tasksRepo: TaskRepository
    private let customersRepo: CustomerRepository
    private let productsRepo: ProductRepository
    private let sourcesRepo: SourceRepository
    private let settingsRepo: SettingsRepository
    private let preferences: PreferencesStore
    private var suppressPersist: Bool = false

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
        self.preferences = PreferencesStore(repo: settings)
    }

    // MARK: - Bootstrap

    func bootstrap() {
        clearLegacyDemoSeedIfNeeded()
        loadPreferences()
        reload()
    }

    /// One-time cleanup: earlier dev builds seeded demo customers/products/tasks/suggestions.
    /// Anyone who launched those builds has a `seeded_v1` flag in settings and rows tied
    /// to the synthetic `demo:slack` source plus a few orphan tasks with no FK link.
    /// Wipe them so the first-run wizard does the real onboarding.
    private func clearLegacyDemoSeedIfNeeded() {
        guard preferences.string(.seededV1ClearedV2) != "true" else { return }
        do {
            // Delete suggestions tied to the demo source (cascade) and the source itself.
            try sourcesRepo.delete(id: "demo:slack")

            // Delete the named demo customers/products and any tasks linked to them.
            let demoCustomerNames = ["Megaflis", "VPG"]
            let demoProductNames  = ["Ticket Agent", "Shop Assistant"]
            for name in demoCustomerNames {
                if let c = try customersRepo.findByName(name) {
                    for t in try tasksRepo.forCustomer(c.id) {
                        try tasksRepo.delete(id: t.id)
                    }
                    try customersRepo.delete(id: c.id)
                }
            }
            for name in demoProductNames {
                if let p = try productsRepo.findByName(name) {
                    for t in try tasksRepo.forProduct(p.id) {
                        try tasksRepo.delete(id: t.id)
                    }
                    try productsRepo.delete(id: p.id)
                }
            }

            // Catch the orphan demo tasks that had no FK links.
            let orphanTitles: Set<String> = [
                "Draft Q2 board update for Megaflis",
                "Review Ticket Agent dedup spec",
                "Reply to VPG procurement contract redlines",
                "Update Stripe pricing tiers in admin",
                "Reply to Frank re: SOC2 timeline",
                "Send Megaflis renewal proposal",
                "Onboard Sondre to ops Slack",
                "Test Ticket Agent webhook with VPG sandbox",
                "Merge GRDB upgrade branch",
                "Confirm investor lunch with Astrid",
            ]
            let allTasks = try tasksRepo.allOpen() + tasksRepo.completedToday()
            for task in allTasks where orphanTitles.contains(task.title) {
                try tasksRepo.delete(id: task.id)
            }
        } catch {
            print("Demo cleanup failed: \(error)")
        }
        preferences.setString(.seededV1Cleared, "true")
        preferences.setString(.seededV1ClearedV2, "true")
    }

    private func loadPreferences() {
        suppressPersist = true
        defer { suppressPersist = false }
        if let raw = preferences.string(.accentPreset),
           let preset = AccentPreset(rawValue: raw) {
            accent = preset
        }
        if let raw = preferences.string(.glyphVariant),
           let variant = GlyphView.Variant(rawValue: raw) {
            glyphVariant = variant
        }
        if let raw = preferences.string(.appearanceMode),
           let mode = AppearanceMode(rawValue: raw) {
            appearance = mode
        }
        showInDock     = preferences.bool(.showInDock, default: false)
        launchAtLogin  = preferences.bool(.launchAtLogin, default: true)
        firstRunComplete = preferences.bool(.firstRunComplete, default: false)
    }

    func markFirstRunComplete() {
        firstRunComplete = true
        preferences.setBool(.firstRunComplete, true)
    }

    private func persistPreferences() {
        guard !suppressPersist else { return }
        preferences.setString(.accentPreset, accent.rawValue)
        preferences.setString(.glyphVariant, glyphVariant.rawValue)
        preferences.setString(.appearanceMode, appearance.rawValue)
        preferences.setBool(.showInDock, showInDock)
        preferences.setBool(.launchAtLogin, launchAtLogin)
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

}
