//
//  File.swift
//  
//
//  Created by ignacio.mendez on 30/06/2022.
//

import Foundation
import Vapor
import Fluent
import JWT

// Example JWT payload.
struct SessionToken: Content, Authenticatable, JWTPayload {
    
    // Constants
    var expirationTime: TimeInterval = 60 * 30
    
    // Token Data
    var expiration: ExpirationClaim
    var userId: UUID
    
    init(userId: UUID) {
        self.userId = userId
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }
    
    init(user: User) throws {
        self.userId = try user.requireID()
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }
    
    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
    }
}

struct ClientTokenReponse: Content {
    var token: String
}
