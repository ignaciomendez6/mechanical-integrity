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
        user.get(":userId", use: getOneUser)
        user.delete(":userId", use: deleteUser)
    }
    
    // http://127.0.0.1:8080/users POST: aca se crea un usuario nuevo si este no existe
    func createUser(req: Request) async throws -> HTTPStatus {
        let user = try req.content.decode(User.self)
        user.password = try Bcrypt.hash(user.password)
        try await user.save(on: req.db)
        return .created // si no existe devuelvo un 201
        
    }
    
    // http://127.0.0.1:8080/users GET: aca muestro todos los usarios
    func getAllusers(req: Request) async throws -> [UserPublic] {
        let users = try await User.query(on: req.db).all()
        var usersPublic: [UserPublic] = []
        for i in 0..<users.count {
            usersPublic.append(UserPublic(id: users[i].id, email: users[i].email))
        }
        return usersPublic // no devuelvo el password al cliente
    }
    
    // http://127.0.0.1:8080/users GET: aca muestro un usuario
    func getOneUser(req: Request) async throws -> UserPublic {
        guard let user = try await  User.find(req.parameters.get("userId"), on: req.db) else {
            throw Abort(.notFound)
        }
        let userPublic = UserPublic(id: user.id, email: user.email)
        return userPublic
    }
    
    // http://127.0.0.1:8080/users:userId Delete: aca elimino un usuario segun su id
    func deleteUser(req: Request) async throws -> HTTPStatus {
        guard let user = try await User.find(req.parameters.get("userId"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await user.delete(on: req.db)
        return .ok
    }
    
    
}

