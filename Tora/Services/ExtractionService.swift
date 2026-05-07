import Foundation
import OSLog

// MARK: - Pricing

/// Default model. User can change via Settings → AI Extraction.
struct ModelOption: Sendable, Hashable {
    let id: String
    let displayName: String
    /// USD per million input tokens.
    let inputPricePerMillion: Double
    /// USD per million output tokens.
    let outputPricePerMillion: Double

    static let defaultModel = ModelOption(
        id: "gpt-5.4-mini",
        displayName: "GPT-5.4 mini",
        inputPricePerMillion: 0.75,
        outputPricePerMillion: 4.50
    )

    static let allOptions: [ModelOption] = [defaultModel]
}

// MARK: - Usage stats

struct UsageStats: Sendable, Equatable {
    var messagesProcessed: Int = 0
    var tasksExtracted: Int = 0
    var inputTokens: Int = 0
    var outputTokens: Int = 0

    func costUSD(model: ModelOption) -> Double {
        let inputCost  = (Double(inputTokens) / 1_000_000) * model.inputPricePerMillion
        let outputCost = (Double(outputTokens) / 1_000_000) * model.outputPricePerMillion
        return inputCost + outputCost
    }
}

// MARK: - Extraction service

/// Buffers signals for `batchInterval` seconds, then sends each through
/// the OpenAI client and persists actionable results as Suggestions.
actor ExtractionService {
    private let logger = Logger(subsystem: "ai.truste.Tora", category: "extraction")
    private let client: OpenAIClient
    private let suggestions: SuggestionRepository
    private let customers: CustomerRepository
    private let products: ProductRepository

    private var buffer: [Signal] = []
    private var flushTask: Task<Void, Never>?
    private(set) var stats = UsageStats()

    var batchInterval: TimeInterval = 30
    var model: ModelOption = .defaultModel
    var apiKey: String?

    /// Called after a new suggestion is persisted. Fires on the actor's executor.
    var onSuggestionCreated: (@Sendable (Suggestion) async -> Void)?

    init(
        client: OpenAIClient = OpenAIClient(),
        suggestions: SuggestionRepository = SuggestionRepository(),
        customers: CustomerRepository = CustomerRepository(),
        products: ProductRepository = ProductRepository()
    ) {
        self.client = client
        self.suggestions = suggestions
        self.customers = customers
        self.products = products
    }

    func configure(apiKey: String?, model: ModelOption, batchInterval: TimeInterval) {
        self.apiKey = apiKey
        self.model = model
        self.batchInterval = batchInterval
    }

    func setSuggestionCreatedHandler(_ handler: @escaping @Sendable (Suggestion) async -> Void) {
        self.onSuggestionCreated = handler
    }

    /// Add a signal to the buffer. Schedules a flush if one isn't pending.
    func enqueue(_ signal: Signal) {
        // Pre-flight dedup: cheap repository check before queueing
        if let existing = try? suggestions.findByHash(signal.contentHash), existing != nil {
            return
        }
        buffer.append(signal)
        scheduleFlush()
    }

    /// Force an immediate flush (used at app shutdown or manual trigger).
    func flushNow() async {
        flushTask?.cancel()
        flushTask = nil
        await drainBuffer()
    }

    private func scheduleFlush() {
        guard flushTask == nil else { return }
        let interval = batchInterval
        flushTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            guard let self else { return }
            await self.drainBuffer()
            await self.clearFlushTask()
        }
    }

    private func clearFlushTask() {
        flushTask = nil
    }

    private func drainBuffer() async {
        guard !buffer.isEmpty else { return }
        guard let apiKey, !apiKey.isEmpty else {
            logger.warning("Skipping extraction — no API key configured")
            buffer.removeAll()
            return
        }

        let pending = buffer
        buffer.removeAll()

        for signal in pending {
            await process(signal: signal, apiKey: apiKey)
        }
    }

    private func process(signal: Signal, apiKey: String) async {
        // Idempotency: skip if hash already exists.
        if let existing = try? suggestions.findByHash(signal.contentHash), existing != nil {
            return
        }

        do {
            let result = try await client.extract(
                signal: signal,
                model: model.id,
                apiKey: apiKey
            )
            stats.messagesProcessed += 1

            guard result.isActionable, let extracted = result.task else { return }
            stats.tasksExtracted += 1

            try await persist(extracted, signal: signal)
        } catch {
            logger.error("Extraction failed: \(String(describing: error), privacy: .public)")
        }
    }

    private func persist(_ extracted: ExtractedTask, signal: Signal) async throws {
        let customerId = try matchCustomer(name: extracted.customer)
        let productId  = try matchProduct(name: extracted.product)
        let due        = parseDate(extracted.suggestedDue)

        let suggestion = Suggestion(
            id: UUID().uuidString,
            sourceId: signal.sourceId,
            title: extracted.title,
            sourcePerson: extracted.sourcePerson,
            sourceChannel: extracted.sourceChannel,
            urgency: extracted.urgency,
            suggestedDue: due,
            contextSnippet: extracted.contextSnippet,
            customerId: customerId,
            productId: productId,
            rawSignalHash: signal.contentHash,
            status: .pending,
            createdAt: Date(),
            actedAt: nil
        )
        try suggestions.save(suggestion)

        if let handler = onSuggestionCreated {
            await handler(suggestion)
        }
    }

    private func matchCustomer(name: String?) throws -> String? {
        guard let name, !name.isEmpty else { return nil }
        return try customers.fuzzyFind(name: name)?.id
    }

    private func matchProduct(name: String?) throws -> String? {
        guard let name, !name.isEmpty else { return nil }
        return try products.fuzzyFind(name: name)?.id
    }

    private func parseDate(_ string: String?) -> Date? {
        guard let string else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.date(from: string)
    }
}
