import XCTest
import GRDB
@testable import Tora

final class DatabaseTests: XCTestCase {
    func test_inMemory_migration_createsAllTables() throws {
        let queue = try DatabaseQueue()
        try Migrator.shared.migrate(queue)

        try queue.read { db in
            XCTAssertTrue(try db.tableExists("sources"))
            XCTAssertTrue(try db.tableExists("customers"))
            XCTAssertTrue(try db.tableExists("products"))
            XCTAssertTrue(try db.tableExists("suggestions"))
            XCTAssertTrue(try db.tableExists("tasks"))
            XCTAssertTrue(try db.tableExists("settings"))
        }
    }

    func test_save_and_fetch_customer() throws {
        let queue = try DatabaseQueue()
        try Migrator.shared.migrate(queue)

        var customer = Customer(id: "c1", name: "Megaflis", notes: nil, createdAt: Date())
        try queue.write { db in try customer.save(db) }

        let fetched = try queue.read { db in try Customer.fetchOne(db, key: "c1") }
        XCTAssertEqual(fetched?.name, "Megaflis")
    }
}
