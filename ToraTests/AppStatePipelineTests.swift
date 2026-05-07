import XCTest
import GRDB
@testable import Tora

@MainActor
final class AppStatePipelineTests: XCTestCase {
    private var queue: DatabaseQueue!
    private var state: AppState!

    override func setUp() async throws {
        queue = try DatabaseQueue()
        try Migrator.shared.migrate(queue)

        let suggestionsRepo = SuggestionRepository(dbQueue: queue)
        let tasksRepo = TaskRepository(dbQueue: queue)
        let customersRepo = CustomerRepository(dbQueue: queue)
        let productsRepo = ProductRepository(dbQueue: queue)
        let sourcesRepo = SourceRepository(dbQueue: queue)
        let settingsRepo = SettingsRepository(dbQueue: queue)

        state = AppState(
            suggestions: suggestionsRepo,
            tasks: tasksRepo,
            customers: customersRepo,
            products: productsRepo,
            sources: sourcesRepo,
            settings: settingsRepo
        )

        // Create a source for the FK
        try sourcesRepo.save(Source(id: "test:slack", type: .slack, label: "Test",
                                     config: nil, active: true, createdAt: Date()))
    }

    func test_seedThenAccept_promotesToTask() throws {
        // Seed one pending suggestion.
        let s = Suggestion(
            id: "s1", sourceId: "test:slack", title: "Send pricing doc",
            sourcePerson: "Frank", sourceChannel: "DM",
            urgency: .high, suggestedDue: nil,
            contextSnippet: "test",
            customerId: nil, productId: nil,
            rawSignalHash: "h1", status: .pending,
            createdAt: Date(), actedAt: nil
        )
        try SuggestionRepository(dbQueue: queue).save(s)

        state.reload()
        XCTAssertEqual(state.suggestions.count, 1)

        state.accept(suggestionId: "s1")

        XCTAssertEqual(state.suggestions.count, 0, "Pending suggestion should be cleared")
        XCTAssertEqual(state.tasks.count, 1, "Should have promoted to a task")
        XCTAssertEqual(state.tasks.first?.title, "Send pricing doc")
    }

    func test_acceptWithCustomerEdit_autoCreatesCustomer() throws {
        let s = Suggestion(
            id: "s2", sourceId: "test:slack", title: "Test",
            sourcePerson: nil, sourceChannel: nil,
            urgency: .medium, suggestedDue: nil, contextSnippet: nil,
            customerId: nil, productId: nil,
            rawSignalHash: "h2", status: .pending,
            createdAt: Date(), actedAt: nil
        )
        try SuggestionRepository(dbQueue: queue).save(s)
        state.reload()

        let edits = InlineAcceptEdits(
            title: "Test", customer: "BrandNewCo", product: "",
            due: "", priority: .medium
        )
        state.accept(suggestionId: "s2", edits: edits)

        let customers = try CustomerRepository(dbQueue: queue).all()
        XCTAssertTrue(customers.contains(where: { $0.name == "BrandNewCo" }))
        XCTAssertEqual(state.tasks.first?.customer, "BrandNewCo")
    }

    func test_dismiss_removesFromInbox() throws {
        let s = Suggestion(
            id: "s3", sourceId: "test:slack", title: "Test",
            sourcePerson: nil, sourceChannel: nil,
            urgency: .low, suggestedDue: nil, contextSnippet: nil,
            customerId: nil, productId: nil,
            rawSignalHash: "h3", status: .pending,
            createdAt: Date(), actedAt: nil
        )
        try SuggestionRepository(dbQueue: queue).save(s)
        state.reload()
        XCTAssertEqual(state.suggestions.count, 1)

        state.dismiss(suggestionId: "s3")
        XCTAssertEqual(state.suggestions.count, 0)
    }

    func test_createManualTask_appearsInTasks() {
        state.reload()
        let initialCount = state.tasks.count
        state.createManualTask(
            title: "Manual entry",
            customer: "Megaflis",
            product: nil,
            due: nil,
            priority: .high
        )
        XCTAssertEqual(state.tasks.count, initialCount + 1)
        XCTAssertEqual(state.tasks.first?.title, "Manual entry")
    }
}
