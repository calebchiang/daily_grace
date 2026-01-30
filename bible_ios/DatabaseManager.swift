//
//  DatabaseManager.swift
//  bible_ios
//
//  Created by Caleb Chiang on 2026-01-29.
//

import Foundation
import GRDB

final class DatabaseManager {

    static let shared = DatabaseManager()
    let dbQueue: DatabaseQueue

    private init() {
        let fileManager = FileManager.default

        let documentURL = fileManager
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dbURL = documentURL.appendingPathComponent("bible_web.sqlite")

        if fileManager.fileExists(atPath: dbURL.path) {
            do {
                try fileManager.removeItem(at: dbURL)
                print("Removed existing DB")
            } catch {
                fatalError("Failed to remove existing DB: \(error)")
            }
        }

        guard let bundledDB = Bundle.main.url(forResource: "bible_web", withExtension: "sqlite") else {
            fatalError("bible_web.sqlite not found in bundle.")
        }

        do {
            try fileManager.copyItem(at: bundledDB, to: dbURL)
            print("Copied bundled DB to Documents folder.")
        } catch {
            fatalError("Failed to copy bundled DB: \(error)")
        }

        do {
            dbQueue = try DatabaseQueue(path: dbURL.path)
            print("Database opened at \(dbURL.path)")

            try dbQueue.read { db in
                let tables = try String.fetchAll(
                    db,
                    sql: "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;"
                )
                print("Tables found in database:", tables)
            }

        } catch {
            fatalError("Failed to open database: \(error)")
        }
    }
}

