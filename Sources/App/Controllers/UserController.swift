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
import SendGrid

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("users") // /users
        usersRoute.post(use: createUser) // /users
        
        usersRoute.post("reset" ,use: sendEmail) // /user/reset
        
        // Creo el token
        let passwordProtected = usersRoute.grouped(User.authenticator(), User.guardMiddleware())
        passwordProtected.post("login", use: login) // /users/login
        
        // Create a route group that requires the SessionToken JWT.
        let secure = usersRoute.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
        secure.get(":userId", use: getOneUser) // /users/userId
        secure.get(use: getAllusers) // /users
        secure.delete(":userId", use: deleteUser) // /users/userId
    }
    
    // http://127.0.0.1:8080/users/reset POST: aca se envia un email para resetear el password
    func sendEmail(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        var emailContent: [String: String] = [:]
            emailContent["type"] = "text/html"
            emailContent["value"] = "Codigo de verificación 1234"//mensaje del email
        let email = SendGridEmail(personalizations: [Personalization(to: [EmailAddress(email: "ignaciomendezing@gmail.com", name: "Ignacio")],//destinatario
                                                                     cc: nil,
                                                                     bcc: nil,
                                                                     subject: "Reset password",//asunto del mail
                                                                     headers: nil,
                                                                     substitutions: nil,
                                                                     dynamicTemplateData: nil,
                                                                     customArgs: nil,
                                                                     sendAt: nil)],
                                  from: EmailAddress(email: "ignaciomendez6@gmail.com", name: "Ignacio"),// quien envía el mail
                                  replyTo: nil,
                                  subject: nil,
                                  content: [emailContent],
                                  attachments: nil,
                                  templateId: nil,
                                  sections: nil,
                                  headers: nil,
                                  categories: nil,
                                  customArgs: nil,
                                  sendAt: nil,
                                  batchId: nil,
                                  asm: nil,
                                  ipPoolName: nil,
                                  mailSettings: nil,
                                  trackingSettings: nil)
        do {
            return try req.application.sendgrid.client.send(emails: [email], on: req.eventLoop).transform(to: HTTPStatus.ok)
        } catch {
            req.logger.error("\(error)")
            return req.eventLoop.makeFailedFuture(error)
        }
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


