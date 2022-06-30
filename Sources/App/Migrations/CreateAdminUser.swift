//
//  File.swift
//  
//
//  Created by ignacio.mendez on 25/06/2022.
//

import Fluent
import Vapor

struct CreateAdminUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let passwordHash: String
        do {
            passwordHash = try Bcrypt.hash("password")
        } catch {
            return database.eventLoop.future(error: error)
        }
        let user = User(email: "admin@gmail.com", password: passwordHash)
        return user.save(on: database)
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        User.query(on: database).filter(\.$email == "admin@gmail.com").delete()
    }
}
