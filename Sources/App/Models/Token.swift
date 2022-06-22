//
//  File.swift
//  
//
//  Created by ignacio.mendez on 22/06/2022.
//

import Foundation
import Vapor
import Fluent
import CloudKit

final class Token: Model, Content {
    static let schema = "tokens"
    
    @ID
    var id: UUID?
    
    @Field(key: "value")
    var value: String
    
    @Parent(key: "userId")
    var user: User
    
    init() {}
    
    init(id: UUID? = nil, value: String, userId: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userId
    }
}

extension Token {
    static func generate(for user: User) throws -> Token {
        let random = [UInt8].random(count: 16).base64
        return try Token(value: random, userId: user.requireID())
    }
}

extension Token: ModelTokenAuthenticatable {
    static let valueKey = \Token.$value
    static let userKey = \Token.$user
    typealias User = App.User
    var isValid: Bool {
        true
    }
}



