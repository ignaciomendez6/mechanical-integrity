//
//  File.swift
//  
//
//  Created by ignacio.mendez on 22/06/2022.
//

import Fluent

struct CreteToken: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("tokens") // table name "tokens", create the table
        // table columns
            .id()
            .field("value", .string, .required)
            .field("userId", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("tokens").delete() // delete the table
    }
    
    
}
