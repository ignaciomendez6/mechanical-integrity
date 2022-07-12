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
        let usersRoute = routes.grouped("users") // http://127.0.0.1:8080/users creo el grupo /users
        usersRoute.post(use: createUser) // http://127.0.0.1:8080/users POST acá creo el usuario
        
        usersRoute.put("checkemail", "code", ":code","id", ":id", use: checkEmail) // PUT http://127.0.0.1:8080/users/checkemail/code/YvI3ZNMx/id/fbdb54b9-b070-4bd8-a47b-e3d75bb09d8c PUT acá verifico el email al hacer sign up, envío un código al email
        
        usersRoute.put("resetpassword", "email", ":email", use: resetPassword) // PUT http://127.0.0.1:8080/users/resetpassword/email/4@gmail.com PUT acá envío un nuevo código al email para resetar el password
        
        usersRoute.put("resetpasswordcheckemail", "code", ":code", "id", ":id", "password", ":password", use: resetPasswordCheckEmail) // PUT http://127.0.0.1:8080/users/resetpasswordcheckemail/code/L6oqyobE/id/fbdb54b9-b070-4bd8-a47b-e3d75bb09d8c/password/44 aca verifico el mail y cambio el password
        
        // Creo el token
        let passwordProtected = usersRoute.grouped(User.authenticator(), User.guardMiddleware())
        passwordProtected.post("login", use: login) // POST http://127.0.0.1:8080/users/login acá envío en headear usuario y password, si está ok devuelve en JWT
        
        // Create a route group that requires the SessionToken JWT.
        let secure = usersRoute.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
        secure.get(":userId", use: getOneUser) // GET http://127.0.0.1:8080/users/323A49A2-3751-4BD8-AFBE-58F8CF26A0D4 obtengo un usuarios, en header el JWT
        secure.get(use: getAllusers) // GET http://127.0.0.1:8080/users obtengo todos los usuarion, en header el JWT
        secure.delete(":userId", use: deleteUser) // DELETE http://127.0.0.1:8080/users/bf6844b8-5a71-4398-a9af-8556b3555f08 elimino un usuario, en header el JWT
    }
    
    // http://127.0.0.1:8080/users POST: aca se crea un usuario nuevo si este no existe y se envía email con código para verificar
    func createUser(req: Request) async throws -> UserPublic {
        print("createUser")
        let user = try req.content.decode(User.self)
        user.password = try Bcrypt.hash(user.password) //encripto la contrasena
        user.codeEmail = [UInt8].random(count: 6).base64 // creo el código para verificar email
        user.checked = false
        user.date = Date() + 5*60
        try await user.save(on: req.db)
        
        let resultEmail = try sendEmail(req: req, code: user.codeEmail, email: user.email) // envío mail con código utilizando el endpoint
        print(resultEmail)
        
        let userPublic = UserPublic(id: user.id, email: user.email)
        return userPublic
    }
    
    // http://127.0.0.1:8080/users/checkemail/code/9689/id/e313421d-6f0f-48a7-86e5-e5410c1bd209 PUT: "checkemail", "code", ":code","id", ":id", se verifica el email
    func checkEmail(req: Request) async throws -> HTTPStatus {
        print("checkemail")
        guard let codeParam = req.parameters.get("code")
        else {
            throw Abort(.badRequest)
        }
        guard let userDb = try await User.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        if (userDb.codeEmail == codeParam) && (userDb.date > Date()) {
            userDb.checked = true
            try await userDb.update(on: req.db)
            
        } else {
            throw Abort(.badRequest)
        }
        return .ok
    }
    
    // http://127.0.0.1:8080/users/login POST: aca se crea el token, mandar en el header Basic auth el email y contrasena
    func login(req: Request) async throws -> ClientTokenReponse {
        print("login")
        let user = try req.auth.require(User.self)
        if user.checked == false {
            throw Abort(.badRequest)
        } else {
            let payload = try SessionToken(user: user)
            return ClientTokenReponse(token: try req.jwt.sign(payload))
        }
    }
    
    // http://127.0.0.1:8080/users/resetpassword/email/ignaciomendezing@gmail.com PUT: Aca reseteo el codigo de verificacion y envio mail al cliente usersRoute.put("resetpassword", "email", ":email", use: resetPassword)
    func resetPassword(req: Request) async throws -> HTTPStatus {
        guard let email = req.parameters.get("email") else {
            throw Abort(.badRequest)
        }
        let users = try await User.query(on: req.db).filter(\.$email == email).first()
        guard let userDb = try await User.find(users?.id, on: req.db) else {
            throw Abort(.badRequest)
        }
        //        userDb.checked = false
        userDb.date = Date() + 5*60
        userDb.codeEmail = [UInt8].random(count: 6).base64 // creo el código para verificar email // creo el código para verificar email
        let resultEmail = try sendEmail(req: req, code: userDb.codeEmail, email: userDb.email)
        print(resultEmail)
        try await userDb.update(on: req.db)
        return .ok
    }
    
    // http://127.0.0.1:8080/users/resetpasswordcheckemail/code/9689/id/e313421d-6f0f-48a7-86e5-e5410c1bd209/password/1234 PUT verificio el código enviado al mail y reseto el password
    func resetPasswordCheckEmail(req: Request) async throws -> HTTPStatus {
        print("checkemail")
        guard let codeParam = req.parameters.get("code"),
              let password = req.parameters.get("password")
        else {
            throw Abort(.badRequest)
        }
        guard let userDb = try await User.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        if (userDb.codeEmail == codeParam) && (userDb.date > Date()) {
            userDb.checked = true
            userDb.password = try Bcrypt.hash(password) //encripto la contrasena
            
            try await userDb.update(on: req.db)
            
        } else {
            throw Abort(.badRequest)
        }
        return .ok
    }
    
    // está funcion en un reedirecionamiento de createUser para enviar el mail
    func sendEmail(req: Request, code: String, email: String) throws -> EventLoopFuture<HTTPStatus> {
        print("sendEmail")
        var emailContent: [String: String] = [:]
        emailContent["type"] = "text/html"
        emailContent["value"] = "Codigo de verificación \(code)"//mensaje del email
        let email = SendGridEmail(personalizations: [Personalization(to: [EmailAddress(email: email, name: email)],//destinatario
                                                                     cc: nil,
                                                                     bcc: nil,
                                                                     subject: "Verificacion de código",//asunto del mail
                                                                     headers: nil,
                                                                     substitutions: nil,
                                                                     dynamicTemplateData: nil,
                                                                     customArgs: nil,
                                                                     sendAt: nil)],
                                  from: EmailAddress(email: "ignaciomendez6@gmail.com", name: "Mechanical Integrity App"),// quien envía el mail
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


