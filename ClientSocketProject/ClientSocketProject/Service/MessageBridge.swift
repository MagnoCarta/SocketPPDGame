//
//  MessageBridge.swift
//  ClientSocketProject
//
//  Created by Gilberto Magno on 14/05/25.
////
//
//import Foundation
//import Network
//
//@MainActor
//final class MessageBridge: ObservableObject {
//    static let shared = MessageBridge()
//
//    private var connections: [NWConnection] = []
//
//    private init() {}
//
//    func register(connection: NWConnection) {
//        if connections.count == 2 { return }
//        connections.append(connection)
//        print("📡 Registered new connection. Total: \(connections.count)")
//        let updateMessage = Message(phase: 0, data: try! JSONEncoder().encode("Player joined"))
//        broadcast(updateMessage)
//    }
//
//    func broadcast(_ message: Message) {
//        let message = Message(phase: message.phase,
//                              data: message.data,
//                              broadcast: false)
//        let data = message.toData()
//
//        for connection in connections {
//            connection.send(content: data, completion: .contentProcessed { error in
//                if let error = error {
//                    print("❌ Failed to send message to a client: \(error)")
//                } else {
//                    print("✅ Message sent to a client: \(message)")
//                }
//            })
//        }
//    }
//
//    func removeDisconnected(_ connection: NWConnection) {
//        connections.removeAll { $0 === connection }
//        print("🛑 Removed disconnected client. Total: \(connections.count)")
//    }
//
//    func reset() {
//        connections.removeAll()
//    }
//    
//    func receiveMessage(_ message: Message) {
//        if message.broadCast {
//            broadcast(message)
//            return
//        }
//
//        switch message.phase {
//        case 1:
//            // Handle Player Join message
//            do {
//                let connectionInfo = try JSONDecoder().decode(ConnectionMessage.self, from: message.data)
//                BoardSession.shared.connection(name: connectionInfo.name,
//                                               number: connectionInfo.number)
//            } catch {
//                print("❌ Failed to decode ConnectionMessage")
//            }
//
//        default:
//            print("📨 Unknown message phase: \(message.phase)")
//        }
//    }
//
//    
//}
//
