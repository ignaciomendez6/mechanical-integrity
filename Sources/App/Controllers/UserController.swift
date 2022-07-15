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
        
        // MARK: - create route /users
        /// http://127.0.0.1:8080/users
        let usersRoute = routes.grouped("users")
        
        // MARK: - POST create user if dosn't exist and send check email
        /// http://127.0.0.1:8080/users
        usersRoute.post(use: createUser)
        
        // MARK: - PUT check email in sign up
        /// http://127.0.0.1:8080/users/checkemail/code/GtsEQ8/id/7e24f183-ec9e-4e50-b9d1-c31c311cca4a
        usersRoute.put("checkemail", "code", ":code","id", ":id", use: checkEmail)
        
        // MARK: - PUT send new code to email to reset password
        /// http://127.0.0.1:8080/users/resetpassword/email/4@gmail.com
        usersRoute.put("resetpassword", "email", ":email", use: resetPassword)
        
        // MARK: - PUT check mail and change password
        /// http://127.0.0.1:8080/users/resetpasswordcheckemail/code/vFADAN/id/7e24f183-ec9e-4e50-b9d1-c31c311cca4a/password/44
        usersRoute.put("resetpasswordcheckemail", "code", ":code", "id", ":id", "password", ":password", use: resetPasswordCheckEmail)
        
        // MARK: - Create token
        let passwordProtected = usersRoute.grouped(User.authenticator(), User.guardMiddleware())
        
        // MARK: - POST send headear mail and password in basic auth ok? -> JWT
        /// http://127.0.0.1:8080/users/login
        passwordProtected.post("login", use: login)
        
        // MARK: - Create a route group that requires the SessionToken JWT.
        let secure = usersRoute.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
        
        // MARK: - GET get one user (header JWT)
        /// http://127.0.0.1:8080/users/323A49A2-3751-4BD8-AFBE-58F8CF26A0D4
        secure.get(":userId", use: getOneUser)
        
        // MARK: - GET get all users (header JWT)
        /// http://127.0.0.1:8080/users
        secure.get(use: getAllusers)
        
        // MARK: - DELETE deleted user with id, en header el JWT
        /// http://127.0.0.1:8080/users/bf6844b8-5a71-4398-a9af-8556b3555f08
        secure.delete(":userId", use: deleteUser)
    }
    
    func createUser(req: Request) async throws -> UserPublic {
        print("createUser")
        let user = try req.content.decode(User.self)
        user.password = try Bcrypt.hash(user.password) //crypt password
        user.codeEmail = String(Int.random(in: 100000 ... 999999)) // code verification create
        user.checked = false
        user.date = Date() + 5*60
        try await user.save(on: req.db)
        let resultEmail = try sendEmail(req: req, code: user.codeEmail ?? "", email: user.email) // send email with code
        print(resultEmail)
        let userPublic = UserPublic(id: user.id, email: user.email)
        return userPublic
    }
    
    func checkEmail(req: Request) async throws -> HTTPStatus {
        print("checkemail")
        guard let codeParam = req.parameters.get("code")
        else {
            throw Abort(.badRequest)
        }
        guard let userDb = try await User.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        if (userDb.codeEmail == codeParam) && (userDb.date ?? Date() > Date()) {
            userDb.checked = true
            try await userDb.update(on: req.db)
            
        } else {
            throw Abort(.badRequest)
        }
        return .ok
    }
    
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
    
    func resetPassword(req: Request) async throws -> UserPublic {
        guard let email = req.parameters.get("email") else {
            throw Abort(.badRequest)
        }
        let users = try await User.query(on: req.db).filter(\.$email == email).first()
        guard let userDb = try await User.find(users?.id, on: req.db) else {
            throw Abort(.badRequest)
        }
        userDb.date = Date() + 5*60
        userDb.codeEmail = String(Int.random(in: 100000 ... 999999)) // create code to check email
        let resultEmail = try sendEmail(req: req, code: userDb.codeEmail ?? "", email: userDb.email)
        print(resultEmail)
        try await userDb.update(on: req.db)
        return UserPublic(id: users?.id, email: email)
    }
    
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
        if (userDb.codeEmail == codeParam) && (userDb.date ?? Date() > Date()) {
            userDb.checked = true
            userDb.password = try Bcrypt.hash(password) // crypt password
            
            try await userDb.update(on: req.db)
            
        } else {
            throw Abort(.badRequest)
        }
        return .ok
    }
    
    // Redirect email
    func sendEmail(req: Request, code: String, email: String) throws -> EventLoopFuture<HTTPStatus> {
        print("sendEmail")
        var emailContent: [String: String] = [:]
        emailContent["type"] = "text/html"
        emailContent["value"] = "Authentication code: \(code)" // message email
        let email = SendGridEmail(personalizations: [Personalization(to: [EmailAddress(email: email, name: email)], // receiver
                                                                     cc: nil,
                                                                     bcc: nil,
                                                                     subject: "Authentication", // email subject
                                                                     headers: nil,
                                                                     substitutions: nil,
                                                                     dynamicTemplateData: nil,
                                                                     customArgs: nil,
                                                                     sendAt: nil)],
                                  from: EmailAddress(email: "ignaciomendez6@gmail.com", name: "Mechanical Integrity App"), // sender
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
    
    func getAllusers(req: Request) async throws -> [UserPublic] {
        print("getAllusers")
        let users = try await User.query(on: req.db).all()
        var usersPublic: [UserPublic] = []
        for i in 0..<users.count {
            usersPublic.append(UserPublic(id: users[i].id, email: users[i].email))
        }
        return usersPublic // no return password
    }
    
    func getOneUser(req: Request) async throws -> UserPublic {
        print("getOneUser")
        guard let user = try await  User.find(req.parameters.get("userId"), on: req.db) else {
            throw Abort(.notFound)
        }
        let userPublic = UserPublic(id: user.id, email: user.email)
        return userPublic
    }
    
    func deleteUser(req: Request) async throws -> HTTPStatus {
        print("deleteUser")
        guard let user = try await User.find(req.parameters.get("userId"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await user.delete(on: req.db)
        return .ok
    }
}


