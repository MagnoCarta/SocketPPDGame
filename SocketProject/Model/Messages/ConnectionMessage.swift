//
//  ConnectionMessage.swift
//  SocketProject
//
//  Created by Gilberto Magno on 14/05/25.
//


import Foundation

struct ConnectionMessage: Codable {
    var name: String
    var number: Int
    
    init(name: String, number: Int) {
        self.name = name
        self.number = number
    }
}
