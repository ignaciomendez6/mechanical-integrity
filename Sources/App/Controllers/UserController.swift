//
//  File.swift
//  
//
//  Created by ignacio.mendez on 20/06/2022.
//

import Fluent
import Vapor
import Crypto

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let user = routes.grouped("users")
        user.post(use: createUser)
        user.get(use: getAllusers)
                
        user.grouped(":userId").delete(use: deleteUser)
    }
    
    // http://127.0.0.1:8080/users aca se crea un usuario nuevo si este no existe
    func createUser(req: Request) async throws -> HTTPStatus {
        let user = try req.content.decode(User.self)
        let userDb = try await User.query(on: req.db).filter(\.$email == user.email).first() // me fijo si el usuario ya existe
        if !(userDb == nil) {
            throw Abort(.badRequest) // si exite devuelvo un 400
        } else {
            user.password = try Bcrypt.hash(user.password)
            try await user.save(on: req.db)
            return .created // si no existe devuelvo un 201
        }
    }
    
    // http://127.0.0.1:8080/users aca muestro todos los usarios
    func getAllusers(req: Request) async throws -> [UserPublic] {
        let users = try await User.query(on: req.db).all()
        var usersPublic: [UserPublic] = []
        for i in 0..<users.count {
            usersPublic.append(UserPublic(id: users[i].id, email: users[i].email))
        }
        return usersPublic // no devuelvo el password al cliente
    }
    
    // http://127.0.0.1:8080/users:userId aca elimino un usuario segun su id
    func deleteUser(req: Request) async throws -> HTTPStatus {
        guard let user = try await User.find(req.parameters.get("userId"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await user.delete(on: req.db)
        return .ok
    }
    
    
}

