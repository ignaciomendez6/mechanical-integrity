//
//  File.swift
//  
//
//  Created by ignacio.mendez on 13/07/2022.
//

import Fluent
import Vapor
import Foundation

struct CalculationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        
        // MARK: - create route /calculations
        /// http://127.0.0.1:8080/calculations
        let calculationRoute = routes.grouped("calculations")
        
        // MARK: - Create a route group that requires the SessionToken JWT.
        let secure = calculationRoute.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
        
        // MARK: - POST shell is calculated (header JWT)
        /// http://127.0.0.1:8080/calculations/shell
        secure.post("shell", use: shell)
        
        // MARK: - POST headEllipsoidal is calculated (header JWT)
        /// http://127.0.0.1:8080/calculations/headEllipsoidal
        secure.post("headEllipsoidal", use: headellipsoidal)
        
        // MARK: - GET get all calculation for a userId
        /// http://127.0.0.1:8080/calculations/getAllCalculation/08fd9e97-4565-49f2-ad30-cf59ecda83b9
        secure.get("getAllCalculation", ":userId", use: getAllCalcultations)
        
        // MARK: - GET get one calculation
        /// http://127.0.0.1:8080/calculations/getOneCalculation/02f2042a-db22-49a0-810d-165c6287950b
        secure.get("getOneCalculation", ":calculationId", use: getOneCalculation)
    }
    
    func shell(req: Request) async throws -> Calculation {
        print("shell")
        let calculation = try req.content.decode(Calculation.self)
        let shell = Shell(P: calculation.P, D: calculation.D, S: calculation.S, E: calculation.E)
        let trShell = shell.trShell()
        calculation.tr = trShell
        calculation.date = Date()
        calculation.component = "shell"
        try await calculation.save(on: req.db)
        return calculation
    }
    
    func headellipsoidal(req: Request) async throws -> Calculation {
        print("headellipsoidal")
        let calculation = try req.content.decode(Calculation.self)
        let headEllipsoidal = HeadEllipsoidal(P: calculation.P, D: calculation.D, S: calculation.S, E: calculation.E)
        let trHeadEllipsoidal = headEllipsoidal.trHeadEllipsoidal()
        calculation.tr = trHeadEllipsoidal
        calculation.date = Date()
        calculation.component = "Head Ellipsoidal"
        try await calculation.save(on: req.db)
        return calculation
    }
    
    func getAllCalcultations(req: Request) async throws -> [Calculation] {
        print("getAllcalculation")
        let id = req.parameters.get("userId") ?? ""
        let uuid = UUID(uuidString: id) ?? UUID()
        let calculations = try await Calculation.query(on: req.db).filter(\.$user.$id == uuid).all()
        return calculations
    }
    
    func getOneCalculation(req: Request) async throws -> Calculation {
        print("getOneCalculation")
        guard let calculation = try await  Calculation.find(req.parameters.get("calculationId"), on: req.db) else {
            throw Abort(.notFound)
        }
        return calculation
    }
}
