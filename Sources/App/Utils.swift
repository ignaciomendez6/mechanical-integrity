//
//  File.swift
//  
//
//  Created by ignacio.mendez on 14/07/2022.
//

//import Foundation
//
//extension String {
//    
//    static var chars: [Character] = {
//        return "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".map({$0})
//    }()
//    
//    static func random(length: Int) -> String {
//        var partial: [Character] = []
//        
//        for _ in 0..<length {
//            let rand = Int(arc4random_uniform(UInt32(chars.count)))
//            partial.append(chars[rand])
//        }
//        
//        return String(partial)
//    }
//}
