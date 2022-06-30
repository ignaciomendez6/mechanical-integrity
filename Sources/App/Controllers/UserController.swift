//
//  File.swift
//
//
//  Created by ignacio.mendez on 20/06/2022.
//

import Fluent
import Vapor
import Crypto
import Foundation

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("users") // /users
        usersRoute.post(use: createUser) // /users
        
        // Creo el token
        let passwordProtected = usersRoute.grouped(User.authenticator(), User.guardMiddleware())
        passwordProtected.post("login", use: login) // /users/login
        
        // Create a route group that requires the SessionToken JWT.
        let secure = usersRoute.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
        secure.get(":userId", use: getOneUser) // /users/userId
        secure.get(use: getAllusers) // /users
        secure.delete(":userId", use: deleteUser) // /users/userId
    }
    
    // http://127.0.0.1:8080/users POST: aca se crea un usuario nuevo si este no existe
    func createUser(req: Request) async throws -> UserPublic {
        print("createUser")
        let user = try req.content.decode(User.self)
        user.password = try Bcrypt.hash(user.password) //encripto la contrasena
        try await user.save(on: req.db)
        let userPublic = UserPublic(id: user.id, email: user.email)
        return userPublic
    }
    
    // http://127.0.0.1:8080/users/login POST: aca se crea el token, mandar en el header Basic auth el email y contrasena
    func login(req: Request) async throws -> ClientTokenReponse {
        print("login")
        let user = try req.auth.require(User.self)
        let payload = try SessionToken(user: user)
        return ClientTokenReponse(token: try req.jwt.sign(payload))
    }
    
    // http://127.0.0.1:8080/users GET: aca muestro todos los usarios
    func getAllusers(req: Request) async throws -> [UserPublic] {
        print("getAllusers")
        let users = try await User.query(on: req.db).all()
        var usersPublic: [UserPublic] = []
        for i in 0..<users.count {
            usersPublic.append(UserPublic(id: users[i].id, email: users[i].email))
        }
        return usersPublic // no devuelvo el password al cliente
    }
    
    // http://127.0.0.1:8080/users:userId GET: aca muestro un usuario
    func getOneUser(req: Request) async throws -> UserPublic {
        print("getOneUser")
        //        let sessionToken = try req.auth.require(SessionToken.self) // me muestra cuando vence en JWT y el ID del usuario
        //        print(sessionToken)
        guard let user = try await  User.find(req.parameters.get("userId"), on: req.db) else {
            throw Abort(.notFound)
        }
        let userPublic = UserPublic(id: user.id, email: user.email)
        return userPublic
    }
    
    // http://127.0.0.1:8080/users:userId Delete: aca elimino un usuario segun su id
    func deleteUser(req: Request) async throws -> HTTPStatus {
        print("deleteUser")
        guard let user = try await User.find(req.parameters.get("userId"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await user.delete(on: req.db)
        return .ok
    }
}


