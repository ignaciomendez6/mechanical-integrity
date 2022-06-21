//
//  File.swift
//  
//
//  Created by ignacio.mendez on 20/06/2022.
//

import Foundation
import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users") // table name "users", create the table
        // table columns
            .id()
            .field("email", .string, .required)
            .field("password", .string, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("users").delete() // delete the table
    }
}
