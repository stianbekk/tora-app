import Foundation
import GRDB

enum DatabaseError: Error {
    case applicationSupportUnavailable
}

final class Database: @unchecked Sendable {
    static let shared = Database()

    let dbQueue: DatabaseQueue

    private init() {
        do {
            let url = try Self.databaseURL()
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            var configuration = Configuration()
            configuration.foreignKeysEnabled = true
            self.dbQueue = try DatabaseQueue(path: url.path, configuration: configuration)
            try Migrator.shared.migrate(dbQueue)
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }

    private static func databaseURL() throws -> URL {
        guard let support = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw DatabaseError.applicationSupportUnavailable
        }
        return support
            .appendingPathComponent("Tora", isDirectory: true)
            .appendingPathComponent("tora.db")
    }
}
