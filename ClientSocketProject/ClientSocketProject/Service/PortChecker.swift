//
//  PortChecker.swift
//  ClientSocketProject
//
//  Created by Gilberto Magno on 14/05/25.
//
//
//import Foundation
//import Network
//
//class PortChecker {
//
//    static func checkPortAvailability(host: NWEndpoint.Host = "127.0.0.1",
//                                      port: UInt16) async -> Bool {
//        return await withCheckedContinuation { continuation in
//            let nwPort = NWEndpoint.Port(rawValue: port)!
//            let connection = NWConnection(host: host, port: nwPort, using: .tcp)
//
//            connection.stateUpdateHandler = { state in
//                switch state {
//                case .ready:
//                    print("🟢 Port \(port) is in use (OPEN).")
//                    continuation.resume(returning: false)
//                    connection.cancel()
//                case .failed, .waiting:
//                    print("🔴 Port \(port) is available (CLOSED).")
//                    continuation.resume(returning: true)
//                    connection.cancel()
//                default:
//                    break
//                }
//            }
//
//            connection.start(queue: .global())
//        }
//    }
//}
