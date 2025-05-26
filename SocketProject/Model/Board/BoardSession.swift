//
//  BoardSession.swift
//  SocketProject
//
//  Created by Gilberto Magno on 14/05/25.
//

import SwiftUI
import Foundation


@Observable
class BoardSession {
    
    static var shared: BoardSession = .init()
    
    var status: StatusPhase = .connecting
    var board: Board = .shared
    
    var turn: Int = 1
    var response: String = ""
    
    var playerNumberOddEven: [OddEven] = [.init(value: 0,
                                                player: 1,
                                                answer: .even),
                                          .init(value: 0,
                                                player: 2,
                                                answer: .odd)]
    
    var players: [String] = [
        "Awaiting Player 1",
        "Awaiting Player 2"
    ]
    
    func connection(name: String,
                    number: Int) {
        if players[number-1] == "Awaiting Player \(number)" {
            players[number-1] = name
        } else {
            // Player X já esta conectado , enviar info de volta
        }
    }
    
    func disconnect(name: String,
                    number: Int) {
        if name == players[number-1] {
            players[number-1] =  "Awaiting Player \(number)"
        }
    }
    
    func oddOrEven(number: Int,
                   player: Int) {
        if playerNumberOddEven[player-1].played { return }
        playerNumberOddEven[player-1].value = number
        playerNumberOddEven[player-1].played = true
        
        if playerNumberOddEven.contains(where: { !$0.played }) {
            return
        }
        
        turn = (playerNumberOddEven[0].value + playerNumberOddEven[1].value)%2 == 0 ? 1 : 2
    }
    
    func placePiece(at finalIndex: Int,
                    player: Int) {
        if player != turn { return }
        if board.squares.filter({ $0.piece.color != .empty }).contains(where: {
            $0.finalIndex == finalIndex
        }) {
            // Fail to Put a piece , visual feedback
        } else {
            board.squares[finalIndex].piece.color = PColors.init(rawValue: turn) ?? .empty
            turn = (turn == 1) ? 2 : 1
        }
    }
    
    func checkVictory() {
        
    }
    
    func nextPhase() {
        status = StatusPhase.init(rawValue: String(status.phaseNumber + 1)) ?? .connecting
    }
    
}



struct BoardView: View {
    @State var session: BoardSession = .shared
    
    @State var username: String = ""
    @State var number: String = ""
    
    var body: some View {
        VStack {
            Text("\(session.status.rawValue)")
            if session.status == .connecting {
                Text(session.response)
            }
            HStack {
                Text("\(session.players[0])")
                Text("X")
                Text("\(session.players[1])")
            }
            LazyVGrid(columns: .init(repeating: .init(spacing: 0),
                                     count: 5), content: {
                ForEach(session.board.squares) { square in
                    Rectangle()
                        .frame(width: 75,height: 75)
                }
            })
        }
    }
}

