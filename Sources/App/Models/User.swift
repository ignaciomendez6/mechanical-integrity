//
//  File.swift
//  
//
//  Created by ignacio.mendez on 20/06/2022.
//

import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users" // table name
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password")
    var password: String
    
    init() { }
    
    init(id: UUID? = nil, email: String, password: String) {
        self.id = id
        self.email = email
        self.password = password
    }
}

final class UserPublic: Content {
    
    var id: UUID?
    
    var email: String
    
    init(id: UUID?, email: String) {
        self.id = id
        self.email = email
    }
}

