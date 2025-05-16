//
//  PlayMessage.swift
//  ClientSocketProject
//
//  Created by Gilberto Magno on 15/05/25.
//

import Foundation

struct PlayMessage: Codable {
    let fromRow: Int?
    let fromCol: Int?
    let toRow: Int
    let toCol: Int
    let phase: String
    let playerNumber: Int
}
