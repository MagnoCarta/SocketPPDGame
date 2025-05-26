//
//  MenuView.swift
//  ClientSocketProject
//
//  Created by Gilberto Magno on 13/05/25.
//
//
//import SwiftUI
//
//struct MenuView: View {
//
//    var body: some View {
//        NavigationStack {
//            Text("Bem vindo ao Seega World!!!!!!!")
//            NavigationLink("Criar nova sala") {
//
//            }
//            NavigationLink("Entrar numa Sala Existente") {
//
//            }
//        }
//    }
//
//}
//
//@Observable
//class RoomAssembler {
//
//    var currentSession: SessionManager?
//    var currentConnectionEstablished: Bool = false
//    var tookTooLongToConnect: Bool = false
//
//    func makeSession(host: String) {
//        let newSession: SessionManager = .init(host: host,
//                                               client: .init(completion: { connected in
//            self.currentConnectionEstablished = connected
//        }))
//        self.currentSession = newSession
//    }
//
//    @ViewBuilder func makeCurrentView() -> some View {
//        if let currentSession {
//            if currentConnectionEstablished {
//                RoomView(sessionManager: currentSession)
//            } else  {
//                Text("Connection Being Established ...")
//                    .task {
//                        Task { [weak self] in
//                            try await Task.sleep(for: .seconds(2.5))
//                            self?.tookTooLongToConnect = true
//                        }
//                    }
//                if tookTooLongToConnect {
//                    Text("Connection Taking Too Long...Try Again")
//                }
//            }
//        } else {
//            Text("Session Being Established...")
//        }
//    }
//
//}
//
//struct CreateRoomView: View {
//
//    @State private var username: String = ""
//    @State var assembler: RoomAssembler = .init()
//
//    var body: some View {
//        TextField("Enter name...", text: $username)
//            .textFieldStyle(RoundedBorderTextFieldStyle())
//            .padding()
//        NavigationLink("Iniciar Sessão com seu nome") {
//            assembler.makeCurrentView()
//                .onAppear {
//                    assembler.makeSession(host: username)
//                }
//        }
//    }
//}
//
//struct RoomView: View {
//
//    init(sessionManager: SessionManager) {
//        self.sessionManager = sessionManager
//    }
//
//    var isCheckingOut: Bool = true
//    var sessionManager: SessionManager
//
//    var body: some View {
//        Text("Sala do Player \(sessionManager.host)")
//        Text("Player One: \(sessionManager.host)")
//        Text("Player Two: \(sessionManager.secondPlayer ?? "")")
//    }
//}
//
//
//@Observable
//class SessionManager {
//    var host: String
//    var secondPlayer: String?
//    var client: TCPClient
//
//    init(host: String,
//         client: TCPClient) {
//        self.host = host
//        self.client = client
//    }
//
//}
//
//
//class Sessions {
//    static var instances: [SessionManager] = []
//}
import SwiftUI

@Observable
class SeegaGameManager {
    
    static var shared: SeegaGameManager = .init()
    
    enum Phase: String, Codable {
        case placing
        case moving
    }

    var board: [[Player?]] = Array(repeating: Array(repeating: nil, count: 5), count: 5)
    var currentPlayer: Player = .player1
    var phase: Phase = .placing
    var selectedCell: (row: Int, col: Int)? = nil
    var message: String = ""
    var winner: Player? = nil
    var myPlayer: Player = ConnectionRoomManager.playerNumber == 1 ? .player1 : .player2
    
    var isChatOpen: Bool = false

    var placedCount: [Player: Int] = [.player1: 0, .player2: 0]

    func tapCell(row: Int, col: Int) {
        guard winner == nil else { return }
        guard currentPlayer == myPlayer else { return }

        if phase == .placing {
            place(row: row, col: col)
        } else {
            if let selected = selectedCell {
                if isValid(from: selected, to: (row, col)) {
                    sendMove(from: selected, to: (row, col))
                }
                selectedCell = nil
            } else if board[row][col] == myPlayer {
                selectedCell = (row, col)
            }
        }
    }

    private func sendMove(from: (row: Int, col: Int)?, to: (row: Int, col: Int)) {
        let move = PlayMessage(
            fromRow: from?.row,
            fromCol: from?.col,
            toRow: to.row,
            toCol: to.col,
            phase: phase.rawValue,
            playerNumber: myPlayer.number
        )
        if let data = try? JSONEncoder().encode(move),
           let json = String(data: data, encoding: .utf8) {
            ConnectionRoomManager.shared.sendMessage(type: .gameMove, content: json)
            applyMove(move)
        }
    }

    private func place(row: Int, col: Int) {
        guard board[row][col] == nil else { return }
        if row == 2 && col == 2 && placedCount[.player1] == 0 && placedCount[.player2] == 0 {
            return
        }
        sendMove(from: nil, to: (row, col))
    }

    func applyMove(_ move: PlayMessage) {
        guard winner == nil else { return }
        let movingPlayer: Player = move.playerNumber == 1 ? .player1 : .player2

        if let fromR = move.fromRow, let fromC = move.fromCol {
            board[move.toRow][move.toCol] = movingPlayer
            board[fromR][fromC] = nil
            capture(from: (move.toRow, move.toCol), player: movingPlayer)
        } else {
            board[move.toRow][move.toCol] = movingPlayer
            placedCount[movingPlayer, default: 0] += 1
        }

        if placedCount[.player1] == 12 && placedCount[.player2] == 12 {
            phase = .moving
        }

        if phase == .moving {
            checkForWinner()
        }
        
        currentPlayer = movingPlayer.opponent
    }

    private func isValid(from: (row: Int, col: Int), to: (row: Int, col: Int)) -> Bool {
        guard board[to.row][to.col] == nil else { return false }
        let dr = abs(from.row - to.row)
        let dc = abs(from.col - to.col)
        return (dr == 1 && dc == 0) || (dr == 0 && dc == 1)
    }

    private func capture(from: (row: Int, col: Int), player: Player) {
        let dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        for dir in dirs {
            let mid = (from.row + dir.0, from.col + dir.1)
            let end = (from.row + dir.0 * 2, from.col + dir.1 * 2)
            guard (0..<5).contains(mid.0), (0..<5).contains(mid.1),
                  (0..<5).contains(end.0), (0..<5).contains(end.1) else { continue }
            if board[mid.0][mid.1] == player.opponent,
               board[end.0][end.1] == player {
                board[mid.0][mid.1] = nil
            }
        }
    }

    private func checkForWinner() {
        let p1 = board.flatMap { $0 }.filter { $0 == .player1 }.count
        let p2 = board.flatMap { $0 }.filter { $0 == .player2 }.count
        if p1 == 0 { winner = .player2 }
        if p2 == 0 { winner = .player1 }
    }
    
    func giveUp(message: String? = nil) {
        if message != nil {
            winner = ConnectionRoomManager.playerNumber == 1 ? .player1 : .player2
            return
        }
        winner = ConnectionRoomManager.playerNumber == 1 ? .player2 : .player1
        let giveupMessage = GiveUpMessage(message: "I Give Up!")
        if let data = try? JSONEncoder().encode(giveupMessage),
           let json = String(data: data, encoding: .utf8) {
            ConnectionRoomManager.shared.sendMessage(type: .giveUp, content: json)
        }
    }
    
    func winByDisconnect() {
        winner = currentPlayer
    }
    
}

enum Player: String, Codable {
    case player1 = "🔴"
    case player2 = "🔵"

    var opponent: Player {
        self == .player1 ? .player2 : .player1
    }

    var number: Int {
        self == .player1 ? 1 : 2
    }
    
    var color: Color {
        self == .player1 ? Color.red : Color.blue
    }
}

struct SeegaGameView: View {
    @State private var game = SeegaGameManager.shared
//    @State private var window: NSWindow?
    @State private var isAlertPresented: Bool = false

    var body: some View {
        HStack {
            if game.isChatOpen {
                ChatView()
                    .transition(.push(from: .leading))
            }
            VStack {
                Text("Seega Multiplayer").font(.title)
                if let winner = game.winner {
                    Text("🏆 Winner: \(winner.rawValue)")
                } else {
                    Text("You are: \(game.myPlayer.rawValue)")
                    Text("Current Turn: \(game.currentPlayer.rawValue)")
                    Text("Phase: \(game.phase.rawValue.capitalized)")
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 4) {
                    ForEach(0..<5) { row in
                        ForEach(0..<5) { col in
                            let piece = game.board[row][col]
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.green.opacity(0.3))
                                    .frame(width: 60,height: 60)
                                    .border(.black)
                                if let piece = piece {
                                    Circle()
                                        .fill(piece.color)
                                        .frame(width: 40, height: 40)
                                }
                            }
                            .onTapGesture {
                                withAnimation {
                                    game.tapCell(row: row, col: col)
                                }
                            }
                        }
                    }
                }.padding()
                ZStack {
                    HStack {
                        Label("Chat",
                              systemImage: "bubble.left.and.text.bubble.right.fill")
                        .onTapGesture {
                            withAnimation {
                                game.isChatOpen.toggle()
                            }
                        }
                        Spacer()
                        Label("Desistir",
                              systemImage: "flag.2.crossed.fill")
                        .foregroundStyle(game.winner != nil ? .gray : .white)
                        .onTapGesture {
                            if game.winner != nil { return }
                            isAlertPresented = true
                        }
                        .alert("Tem certeza que quer desistir?",
                               isPresented: $isAlertPresented,
                               actions: {
                            HStack {
                                Button("Sim") {
                                    game.giveUp()
                                    isAlertPresented = false
                                }
                                Button("Não") {
                                    isAlertPresented = false
                                }
                            }
                        })
                    }
                    .font(.title2)
                    .padding()
                }
            }
        }
//        .background(WindowAccessor(window: $window))
//        .onChange(of: window) {
//            window?.setFrame(NSRect(origin: .init(x: 410, y: 270) , size: .init(width: 425, height: 580)), display: true, animate: true)
//        }
//        .onChange(of: game.isChatOpen) {
//            window?.setFrame(NSRect(origin: .init(x: 410, y: 270) , size: .init(width: game.isChatOpen ? 665 : 425, height: 580)), display: true, animate: true)
//        }
        .onAppear {
            ConnectionRoomManager.shared.handlePlayMessage = { play in
                withAnimation {
                    game.applyMove(play)
                }
            }
            ConnectionRoomManager.shared.giveUpMessage = { giveup in
                withAnimation {
                    game.giveUp(message:  giveup.message)
                }
            }
        }
    }
}
