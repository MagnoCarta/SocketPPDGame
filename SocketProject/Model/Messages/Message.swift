//
//  Message.swift
//  SocketProject
//
//  Created by Gilberto Magno on 14/05/25.
//
//
//import Foundation
//
//struct Message: Codable, Sendable {
//    let broadCast: Bool
//    let phase: Int
//    let data: Data
//    
//    init(phase: Int,
//         data: Data,
//         broadcast: Bool = true) {
//        self.phase = phase
//        self.data = data
//        self.broadCast = broadcast
//    }
//    
//    func toData() -> Data? {
//        do {
//            return try JSONEncoder().encode(self)
//        } catch {
//            print("Fail to encode") // add visual feedback
//            return nil
//        }
//    }
//}
//
//extension Data {
//    func decodeMessage() -> Message? {
//        do {
//            return try JSONDecoder().decode(Message.self,
//                                     from: self)
//        } catch {
//            print("Fail to decode") // add visual feedback
//            return nil
//        }
//    }
//}
