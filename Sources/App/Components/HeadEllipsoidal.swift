//
//  File.swift
//  
//
//  Created by ignacio.mendez on 14/07/2022.
//

import Foundation

final class HeadEllipsoidal {
    // Properties
    let P, D, S, E: Double
    
    // Init
    init(P: Double, D: Double, S: Double, E: Double) {
        self.P = P
        self.D = D
        self.S = S
        self.E = E
    }
    
    // Method
    func trHeadEllipsoidal() -> Double {
        var tr: Double
        
        tr = ((P * D) / (2 * S * E + 1.8 * P)) * 25.4
        
        if tr < 1.6 {
            tr = 1.6
        }
        
        return tr
    }
}
