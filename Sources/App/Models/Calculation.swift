//
//  File.swift
//  
//
//  Created by ignacio.mendez on 13/07/2022.
//

import Fluent
import Vapor

final class Calculation: Model, Content {
    
    static let schema = "calculations" // table name
    
    @ID(key: .id) // PK (primary key)
    var id: UUID?
    
    // Calculation belong to a user
    @Parent(key: "user_id") // FK (foregin key)
    var user: User
    
    @Field(key: "component")
    var component: String?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "tr")
    var tr: Double?
    
    @Field(key: "date")
    var date: Date?
    
    @Field(key: "P")
    var P: Double
    
    @Field(key: "D")
    var D: Double
    
    @Field(key: "S")
    var S: Double
    
    @Field(key: "E")
    var E: Double
    
    init() { }
    
    init(id: UUID? = nil, userId: UUID, component: String, name: String, date: Date, tr: Double, P: Double, D: Double, S: Double, E: Double) {
        self.id = id
        self.$user.id = userId
        self.component = component
        self.name = name
        self.date = date
        self.tr = tr
        self.P = P
        self.D = D
        self.S = S
        self.E = E
    }
}
