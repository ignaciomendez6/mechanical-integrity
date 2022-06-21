//
//  File.swift
//  
//
//  Created by ignacio.mendez on 20/06/2022.
//

import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let user = routes.grouped("users")
        user.post(use: create)
        user.get(use: index)
    }
    
    // http://127.0.0.1:8080/users aca se crea un usuario
    func create(req: Request) async throws -> User {
        let user = try req.content.decode(User.self)
        try await user.save(on: req.db)
        return user
    }
    
    // http://127.0.0.1:8080/users aca muestro todos los usarios
    func index(req: Request) async throws -> [User] {
        let users = try await User.query(on: req.db).all()
        return users
    }
}

