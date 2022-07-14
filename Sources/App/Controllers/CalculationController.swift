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
        let calculationRoute = routes.grouped("calculations") // http://127.0.0.1:8080/calculations creo el grupo /users
        
        // Create a route group that requires the SessionToken JWT.
        let secure = calculationRoute.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
        secure.post("shell", use: shell) // POST http://127.0.0.1:8080/calculations/shell POST acá calculo la envolvente
        secure.get("getAllCalculation", ":userId", use: getAllCalcultations) // GET http://127.0.0.1:8080/calculations/getAllCalculation/dasdsadasd654564654 me traigo todos los calculos de ese userId
        secure.get("getOneCalculation", ":calculationId", use: getOneCalculation) // GET http://127.0.0.1:8080/calculations/getOneCalculation/dasdsadasd654564654 me traigo un solo usuario
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
    
    func getAllCalcultations(req: Request) async throws -> [Calculation] {
        print("getAllcalculation")
        
        let id = req.parameters.get("userId") ?? ""
        let uuid = UUID(uuidString: id) ?? UUID()
        
        let calculations = try await Calculation.query(on: req.db).filter(\.$user.$id == uuid).all()
        
        return calculations // no devuelvo el password al cliente
    }
    
    func getOneCalculation(req: Request) async throws -> Calculation {
        print("getOneCalculation")
        guard let calculation = try await  Calculation.find(req.parameters.get("calculationId"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return calculation
    }
}
