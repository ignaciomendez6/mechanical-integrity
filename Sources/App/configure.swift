import Fluent
import FluentPostgresDriver
import Vapor
import Leaf
import SendGrid

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
//    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
//    app.middleware.use(app.sessions.middleware)
    
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "postgres",
        password: Environment.get("DATABASE_PASSWORD") ?? "",
        database: Environment.get("DATABASE_NAME") ?? "mi_database"
    ), as: .psql)
    
    app.migrations.add(CreateUser())
    app.migrations.add(CreateCalculation())
    
    // Add HMAC with SHA-256 signer.
    guard let key = Environment.process.JWT else { // enviroment variable set in scheme fon JWT sign
        fatalError("No secret sign JWT provided")
    }
    app.jwt.signers.use(.hs256(key: key)) // contraseña para firmar el JWT, esto debería ser una variable de entorno?
    
    app.sendgrid.initialize()
    
    // register routes
    try routes(app)
}
