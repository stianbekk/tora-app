import Foundation
import GRDB

// MARK: - Source

struct Source: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Hashable {
    static let databaseTableName = "sources"

    enum Kind: String, Codable {
        case slack
        case gmail
    }

    var id: String
    var type: Kind
    var label: String
    var config: String?
    var active: Bool
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case label
        case config
        case active
        case createdAt = "created_at"
    }
}

// MARK: - Customer

struct Customer: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Hashable {
    static let databaseTableName = "customers"

    var id: String
    var name: String
    var notes: String?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case notes
        case createdAt = "created_at"
    }
}

// MARK: - Product

struct Product: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Hashable {
    static let databaseTableName = "products"

    var id: String
    var name: String
    var customerId: String?
    var notes: String?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case customerId = "customer_id"
        case notes
        case createdAt = "created_at"
    }
}

// MARK: - Suggestion

struct Suggestion: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Hashable {
    static let databaseTableName = "suggestions"

    enum Urgency: String, Codable, CaseIterable {
        case low
        case medium
        case high
    }

    enum Status: String, Codable {
        case pending
        case accepted
        case dismissed
    }

    var id: String
    var sourceId: String
    var title: String
    var sourcePerson: String?
    var sourceChannel: String?
    var urgency: Urgency
    var suggestedDue: Date?
    var contextSnippet: String?
    var customerId: String?
    var productId: String?
    var rawSignalHash: String?
    var status: Status
    var createdAt: Date
    var actedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case sourceId = "source_id"
        case title
        case sourcePerson = "source_person"
        case sourceChannel = "source_channel"
        case urgency
        case suggestedDue = "suggested_due"
        case contextSnippet = "context_snippet"
        case customerId = "customer_id"
        case productId = "product_id"
        case rawSignalHash = "raw_signal_hash"
        case status
        case createdAt = "created_at"
        case actedAt = "acted_at"
    }
}

// MARK: - Task

struct ToraTask: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Hashable {
    static let databaseTableName = "tasks"

    enum Priority: Int, Codable, CaseIterable {
        case high = 1
        case medium = 2
        case low = 3
    }

    var id: String
    var suggestionId: String?
    var title: String
    var notes: String?
    var priority: Priority
    var dueDate: Date?
    var customerId: String?
    var productId: String?
    var completed: Bool
    var completedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case suggestionId = "suggestion_id"
        case title
        case notes
        case priority
        case dueDate = "due_date"
        case customerId = "customer_id"
        case productId = "product_id"
        case completed
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - AppSetting (key-value)

struct AppSetting: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "settings"

    var key: String
    var value: String
}
