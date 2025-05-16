import Foundation
import Network
import Observation
import SwiftUI

@Observable
class ConnectionRoomManager {
    static var playerNumber: Int = 0
    static let shared = ConnectionRoomManager()

    enum State {
        case offline, hosting, connected, joining
    }

    var state: State = .offline
    var messages: [Message] = []
    var hostIP: String = "10.200.201.34"
    var port: UInt16 = 8080
    var input: String = ""
    var navigateToGame: () -> Void = {}
    var handlePlayMessage: (PlayMessage) -> Void = { _ in }
    var giveUpMessage: (GiveUpMessage) -> Void = { _ in }

    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private var myConnection: NWConnection?

    func hostRoom() {
        Task { @SocketActor in
            self.state = .hosting
            do {
                listener = try NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: port)!)
                listener?.newConnectionHandler = { [weak self] newConnection in
                    guard let self else { return }
                    self.setupConnection(newConnection)
                }
                listener?.start(queue: .main)
                Self.playerNumber = 1
            } catch {
                print("Failed to start listener: \(error)")
                self.state = .offline
            }
        }
    }

    func joinRoom() {
        Task { @SocketActor in
            state = .joining
            let host = NWEndpoint.Host(hostIP)
            let port = NWEndpoint.Port(rawValue: port)!
            let conn = NWConnection(host: host, port: port, using: .tcp)
            myConnection = conn

            conn.stateUpdateHandler = { [weak self] state in
                guard let self else { return }
                switch state {
                case .ready:
                    Task { @MainActor in
                        self.state = .connected
                        Self.playerNumber = 2
                    }
                    Task { @SocketActor in self.receive(on: conn) }
                case .failed(let error):
                    print("❌ Connection failed: \(error)")
                    Task { @MainActor in self.state = .offline }
                    Task { await self.remove(conn) }
                case .cancelled:
                    print("🚫 Connection cancelled")
                    Task { await self.remove(conn) }
                    SeegaGameManager.shared.winByDisconnect()
                default:
                    break
                }
            }

            conn.start(queue: .main)
        }
    }

    func sendMessage(type: MessageType, content: String) {
        Task { @SocketActor in
            let message = Message(id: UUID(), sender: "Player \(Self.playerNumber)", type: type, content: content, broadcast: true)
            guard let jsonData = try? JSONEncoder().encode(message) else { return }

            var length = UInt32(jsonData.count).bigEndian
            var fullData = Data(bytes: &length, count: 4)
            fullData.append(jsonData)

            for conn in connections {
                conn.send(content: fullData, completion: .contentProcessed { _ in })
            }

            myConnection?.send(content: fullData, completion: .contentProcessed { _ in })

            Task { @MainActor in
                self.messages.append(message)
                self.input = ""
            }
        }
    }

    private func setupConnection(_ connection: NWConnection) {
        connections.append(connection)

        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                Task { @MainActor in self.state = .connected }
                self.receive(on: connection)
            case .failed(let error):
                print("❌ Connection failed: \(error)")
                Task { await self.remove(connection) }
            case .cancelled:
                print("🚫 Connection cancelled")
                Task { await self.remove(connection) }
            default:
                break
            }
        }

        connection.start(queue: .main)
    }

    @SocketActor
    private func remove(_ connection: NWConnection) {
        self.connections.removeAll { $0 === connection }
        if self.myConnection === connection {
            self.myConnection = nil
        }
    }

    private func receive(on connection: NWConnection) {
        func receiveLength() {
            connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] lengthData, _, isComplete, _ in
                guard let self, let lengthData, lengthData.count == 4 else {
                    connection.cancel()
                    Task { await self?.remove(connection) }
                    return
                }
                if isComplete {
                    connection.cancel()
                    Task { await self.remove(connection) }
                    return
                }
                let length = lengthData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
                receiveMessage(of: Int(length))
            }
        }

        func receiveMessage(of length: Int) {
            print("📦 Waiting to receive \(length) bytes from \(connection.endpoint)")

            connection.receive(minimumIncompleteLength: length, maximumLength: length) { [weak self] data, _, isComplete, _ in
                print("✅ .receive closure fired for \(length) bytes")
                guard let self, let data else {
                    connection.cancel()
                    Task { await self?.remove(connection) }
                    return
                }
                if isComplete {
                    connection.cancel()
                    Task { await self.remove(connection) }
                    return
                }

                guard var message = try? JSONDecoder().decode(Message.self, from: data),
                      !self.messages.contains(where: { $0.id == message.id }) else {
                    receiveLength()
                    return
                }

                Task { @MainActor in
                    self.messages.append(message)

                    switch message.type {
                    case .gameStart:
                        self.navigateToGame()
                    case .gameMove:
                        if let data = message.content.data(using: .utf8),
                           let play = try? JSONDecoder().decode(PlayMessage.self, from: data) {
                            self.handlePlayMessage(play)
                        }
                    case .giveUp:
                        if let data = message.content.data(using: .utf8),
                           let play = try? JSONDecoder().decode(GiveUpMessage.self, from: data) {
                            self.giveUpMessage(play)
                        }
                    case .text:
                        break
                    }
                }

                if message.broadcast {
                    message = Message(id: message.id, sender: message.sender, type: message.type, content: message.content, broadcast: false)
                    if let forwardData = try? JSONEncoder().encode(message) {
                        var length = UInt32(forwardData.count).bigEndian
                        var fullData = Data(bytes: &length, count: 4)
                        fullData.append(forwardData)

                        Task { @SocketActor in
                            for conn in self.connections where conn !== connection {
                                conn.send(content: fullData, completion: .contentProcessed { _ in })
                            }
                            if self.myConnection !== connection {
                                self.myConnection?.send(content: fullData, completion: .contentProcessed { _ in })
                            }
                        }
                    }
                }
                receiveLength()
            }
        }

        receiveLength()
    }
}


struct ChatView: View {
    @State private var manager = ConnectionRoomManager.shared
    
    var body: some View {
        VStack {
            List(manager.messages) { msg in
                Text("\(msg.sender): \(msg.content)")
            }
            ZStack {
                HStack {
                    TextField("Message", text: $manager.input)
                        .textFieldStyle(.roundedBorder)
                    Button("Send") {
                        manager.sendMessage(type: .text, content: manager.input)
                    }
                    .disabled(manager.input.isEmpty || manager.state != .connected)
                }
                .padding(.vertical)
            }
        }
    }
}
