//
//  Board.swift
//  SocketProject
//
//  Created by Gilberto Magno on 14/05/25.
//

import Foundation
import SwiftUI

class Board {
   
    static var shared: Board = .init()
    
    var initialSquares: [Square] = {
        var iSquares: [Square] = []
        var finalIndex: Int = 0
        (0...4).forEach { rIndex in
            (0...4).forEach { cIndex in
                iSquares.append(.init(piece: .init(),
                                      finalIndex: finalIndex))
                finalIndex += 1
            }
        }
        return iSquares
    }()
    var squares: [Square] = []
    
    private init() {
        setup()
    }
    
    func setup() {
        squares = initialSquares
    }
}

enum StatusPhase: String {
    case connecting = "Conectando..."
    case oddOrEven = "Par ou Impar"
    case setupBoard = "Configurar Tabuleiro"
    case gameStarted = "Jogo em Andamento"
    case gameFinished = "Jogo Finalizado"
    
    var phaseNumber: Int {
        switch self {
        case .connecting:
            0
        case .oddOrEven:
            1
        case .setupBoard:
            2
        case .gameStarted:
            3
        case .gameFinished:
            4
        }
    }
}

class Square: Identifiable {
    var piece: Piece
    var finalIndex: Int
    
    init(piece: Piece,
         finalIndex: Int) {
        self.piece = piece
        self.finalIndex = finalIndex
    }
}

struct Piece {
    var color: PColors = .empty
}


enum PColors: Int {
    case yellow = 1, green = 2, empty = 0
    var color: Color {
        switch self {
        case .yellow:
            return .yellow
        case .green:
            return .green
        case .empty:
            return .clear
        }
    }
}

struct OddEven {
    var value: Int
    var player: Int
    var played: Bool = false
    var answer: OddEvenAnswer
}

enum OddEvenAnswer: String {
    case even = "Par",
         odd = "Impar"
}
