//
//  File.swift
//  
//
//  Created by ignacio.mendez on 13/07/2022.
//

import Foundation
import Fluent

struct CreateCalculation: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("calculations") // table name "users", create the table
        // table columns
            .id()
            .field("user_id", .uuid, .references("users", "id"))
            .field("component", .string)
            .field("name", .string)
            .field("date", .datetime)
            .field("tr", .double)
            .field("P", .double)
            .field("D", .double)
            .field("S", .double)
            .field("E", .double)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("calculations").delete() // delete the table
    }
}
