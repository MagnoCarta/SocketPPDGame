//
//  ConnectionMessage.swift
//  ClientSocketProject
//
//  Created by Gilberto Magno on 13/05/25.
//

import Foundation

class ConnectionMessage: Codable {
    var name: String
    var number: Int
    
    init(name: String, number: Int) {
        self.name = name
        self.number = number
    }
}
