import Foundation
import GRDB

struct Migrator {
    static let shared = Migrator()

    func migrate(_ writer: any DatabaseWriter) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("001_initial") { db in
            try db.create(table: "sources") { t in
                t.column("id", .text).primaryKey()
                t.column("type", .text).notNull()
                t.column("label", .text).notNull()
                t.column("config", .text)
                t.column("active", .integer).notNull().defaults(to: 1)
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
            }

            try db.create(table: "customers") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("notes", .text)
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
            }

            try db.create(table: "products") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("customer_id", .text).references("customers", onDelete: .setNull)
                t.column("notes", .text)
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
            }

            try db.create(table: "suggestions") { t in
                t.column("id", .text).primaryKey()
                t.column("source_id", .text).notNull().references("sources", onDelete: .cascade)
                t.column("title", .text).notNull()
                t.column("source_person", .text)
                t.column("source_channel", .text)
                t.column("urgency", .text).notNull().defaults(to: "medium")
                t.column("suggested_due", .datetime)
                t.column("context_snippet", .text)
                t.column("customer_id", .text).references("customers", onDelete: .setNull)
                t.column("product_id", .text).references("products", onDelete: .setNull)
                t.column("raw_signal_hash", .text)
                t.column("status", .text).notNull().defaults(to: "pending")
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.column("acted_at", .datetime)
            }
            try db.create(index: "idx_suggestions_status", on: "suggestions", columns: ["status"])
            try db.create(index: "idx_suggestions_hash", on: "suggestions", columns: ["raw_signal_hash"])

            try db.create(table: "tasks") { t in
                t.column("id", .text).primaryKey()
                t.column("suggestion_id", .text).references("suggestions", onDelete: .setNull)
                t.column("title", .text).notNull()
                t.column("notes", .text)
                t.column("priority", .integer).notNull().defaults(to: 2)
                t.column("due_date", .datetime)
                t.column("customer_id", .text).references("customers", onDelete: .setNull)
                t.column("product_id", .text).references("products", onDelete: .setNull)
                t.column("completed", .integer).notNull().defaults(to: 0)
                t.column("completed_at", .datetime)
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.column("updated_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
            }
            try db.create(index: "idx_tasks_completed", on: "tasks", columns: ["completed"])
            try db.create(index: "idx_tasks_due", on: "tasks", columns: ["due_date"])

            try db.create(table: "settings") { t in
                t.column("key", .text).primaryKey()
                t.column("value", .text)
            }
        }

        try migrator.migrate(writer)
    }
}
