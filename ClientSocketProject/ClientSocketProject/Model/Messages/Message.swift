//
//  Message.swift
//  ClientSocketProject
//
//  Created by Gilberto Magno on 12/05/25.
//

import Foundation

// Por se tratar de um jogo com comunicação muito simples, optei por não utilizar conceitos mais finos, como sempre enviar Events, e esses eventos serem decodificados em Messagens, aqui eu apenas criei mensagens com tipos diferentes
enum MessageType: String, Codable {
    case text
    case gameStart
    case gameMove
    case giveUp
}

struct Message: Codable, Identifiable, Equatable {
    let id: UUID
    let sender: String
    let type: MessageType
    let content: String
    let broadcast: Bool
}
