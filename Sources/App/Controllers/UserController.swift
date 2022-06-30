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
        let usersRoute = routes.grouped("users")
        usersRoute.get(use: getAllusers)
//        usersRoute.get(":userId", use: getOneUser)
        usersRoute.delete(":userId", use: deleteUser)
        
        let basicAuthMiddleware = User.authenticator()
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: login)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(use: createUser) // para hacer esta request, en los header se debe pasar el token que crea el admin user
        
        tokenAuthGroup.get(":userId", use: getOneUser)
    }
    
    // http://127.0.0.1:8080/users/login POST: valida si existe el usuario en la base de datos y devuelve el token
    func login(req: Request) async throws -> Token {
        print("login")
        let user = try req.auth.require(User.self)
        let token = try Token.generate(for: user)
        try await token.save(on: req.db)
        return token
    }
    
    // http://127.0.0.1:8080/users POST: aca se crea un usuario nuevo si este no existe
    func createUser(req: Request) async throws -> UserPublic {
        print("createUser")
        let user = try req.content.decode(User.self)
        user.password = try Bcrypt.hash(user.password)
        try await user.save(on: req.db)
        let userPublic = UserPublic(id: user.id, email: user.email)
        return userPublic
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
    
    // http://127.0.0.1:8080/users GET: aca muestro un usuario
    func getOneUser(req: Request) async throws -> UserPublic {
        print("getOneUser")
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

