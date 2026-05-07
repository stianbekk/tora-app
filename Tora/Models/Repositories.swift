import Foundation
import GRDB

// MARK: - Repository protocol

protocol Repository {
    associatedtype Model

    func all() throws -> [Model]
    func find(id: String) throws -> Model?
    func save(_ model: Model) throws
    func delete(id: String) throws
}

// MARK: - SourceRepository

struct SourceRepository {
    let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue = Database.shared.dbQueue) {
        self.dbQueue = dbQueue
    }

    func all() throws -> [Source] {
        try dbQueue.read { db in
            try Source.order(Column("created_at").desc).fetchAll(db)
        }
    }

    func active() throws -> [Source] {
        try dbQueue.read { db in
            try Source.filter(Column("active") == 1).fetchAll(db)
        }
    }

    func find(id: String) throws -> Source? {
        try dbQueue.read { db in try Source.fetchOne(db, key: id) }
    }

    func save(_ source: Source) throws {
        try dbQueue.write { db in
            var copy = source
            try copy.save(db)
        }
    }

    func delete(id: String) throws {
        _ = try dbQueue.write { db in try Source.deleteOne(db, key: id) }
    }
}

// MARK: - CustomerRepository

struct CustomerRepository {
    let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue = Database.shared.dbQueue) {
        self.dbQueue = dbQueue
    }

    func all() throws -> [Customer] {
        try dbQueue.read { db in
            try Customer.order(Column("name")).fetchAll(db)
        }
    }

    func find(id: String) throws -> Customer? {
        try dbQueue.read { db in try Customer.fetchOne(db, key: id) }
    }

    func findByName(_ name: String) throws -> Customer? {
        try dbQueue.read { db in
            try Customer.filter(Column("name") == name).fetchOne(db)
        }
    }

    func save(_ customer: Customer) throws {
        try dbQueue.write { db in
            var copy = customer
            try copy.save(db)
        }
    }

    func delete(id: String) throws {
        _ = try dbQueue.write { db in try Customer.deleteOne(db, key: id) }
    }

    func taskCount(customerId: String) throws -> Int {
        try dbQueue.read { db in
            try ToraTask
                .filter(Column("customer_id") == customerId && Column("completed") == 0)
                .fetchCount(db)
        }
    }
}

// MARK: - ProductRepository

struct ProductRepository {
    let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue = Database.shared.dbQueue) {
        self.dbQueue = dbQueue
    }

    func all() throws -> [Product] {
        try dbQueue.read { db in
            try Product.order(Column("name")).fetchAll(db)
        }
    }

    func forCustomer(_ customerId: String) throws -> [Product] {
        try dbQueue.read { db in
            try Product.filter(Column("customer_id") == customerId).fetchAll(db)
        }
    }

    func find(id: String) throws -> Product? {
        try dbQueue.read { db in try Product.fetchOne(db, key: id) }
    }

    func findByName(_ name: String) throws -> Product? {
        try dbQueue.read { db in
            try Product.filter(Column("name") == name).fetchOne(db)
        }
    }

    func save(_ product: Product) throws {
        try dbQueue.write { db in
            var copy = product
            try copy.save(db)
        }
    }

    func delete(id: String) throws {
        _ = try dbQueue.write { db in try Product.deleteOne(db, key: id) }
    }

    func taskCount(productId: String) throws -> Int {
        try dbQueue.read { db in
            try ToraTask
                .filter(Column("product_id") == productId && Column("completed") == 0)
                .fetchCount(db)
        }
    }
}

// MARK: - SuggestionRepository

struct SuggestionRepository {
    let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue = Database.shared.dbQueue) {
        self.dbQueue = dbQueue
    }

    func pending() throws -> [Suggestion] {
        try dbQueue.read { db in
            try Suggestion
                .filter(Column("status") == Suggestion.Status.pending.rawValue)
                .order(Column("created_at").desc)
                .fetchAll(db)
        }
    }

    func count(status: Suggestion.Status) throws -> Int {
        try dbQueue.read { db in
            try Suggestion.filter(Column("status") == status.rawValue).fetchCount(db)
        }
    }

    func find(id: String) throws -> Suggestion? {
        try dbQueue.read { db in try Suggestion.fetchOne(db, key: id) }
    }

    func findByHash(_ hash: String) throws -> Suggestion? {
        try dbQueue.read { db in
            try Suggestion.filter(Column("raw_signal_hash") == hash).fetchOne(db)
        }
    }

    func save(_ suggestion: Suggestion) throws {
        try dbQueue.write { db in
            var copy = suggestion
            try copy.save(db)
        }
    }

    func delete(id: String) throws {
        _ = try dbQueue.write { db in try Suggestion.deleteOne(db, key: id) }
    }
}

// MARK: - TaskRepository

struct TaskRepository {
    let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue = Database.shared.dbQueue) {
        self.dbQueue = dbQueue
    }

    func allOpen() throws -> [ToraTask] {
        try dbQueue.read { db in
            try ToraTask
                .filter(Column("completed") == 0)
                .order(Column("priority"), Column("due_date"))
                .fetchAll(db)
        }
    }

    func dueToday() throws -> [ToraTask] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return try dbQueue.read { db in
            try ToraTask
                .filter(Column("completed") == 0)
                .filter(Column("due_date") >= start && Column("due_date") < end)
                .fetchAll(db)
        }
    }

    func completedToday() throws -> [ToraTask] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        return try dbQueue.read { db in
            try ToraTask
                .filter(Column("completed") == 1)
                .filter(Column("completed_at") >= start)
                .fetchAll(db)
        }
    }

    func forCustomer(_ customerId: String) throws -> [ToraTask] {
        try dbQueue.read { db in
            try ToraTask.filter(Column("customer_id") == customerId).fetchAll(db)
        }
    }

    func forProduct(_ productId: String) throws -> [ToraTask] {
        try dbQueue.read { db in
            try ToraTask.filter(Column("product_id") == productId).fetchAll(db)
        }
    }

    func find(id: String) throws -> ToraTask? {
        try dbQueue.read { db in try ToraTask.fetchOne(db, key: id) }
    }

    func save(_ task: ToraTask) throws {
        try dbQueue.write { db in
            var copy = task
            copy.updatedAt = Date()
            try copy.save(db)
        }
    }

    func delete(id: String) throws {
        _ = try dbQueue.write { db in try ToraTask.deleteOne(db, key: id) }
    }
}

// MARK: - SettingsRepository

struct SettingsRepository {
    let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue = Database.shared.dbQueue) {
        self.dbQueue = dbQueue
    }

    func get(_ key: String) throws -> String? {
        try dbQueue.read { db in
            try AppSetting.fetchOne(db, key: key)?.value
        }
    }

    func set(_ key: String, value: String) throws {
        try dbQueue.write { db in
            var setting = AppSetting(key: key, value: value)
            try setting.save(db)
        }
    }

    func delete(_ key: String) throws {
        _ = try dbQueue.write { db in try AppSetting.deleteOne(db, key: key) }
    }
}
