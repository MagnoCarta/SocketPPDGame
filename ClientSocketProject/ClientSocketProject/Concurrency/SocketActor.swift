//
//  SocketActor.swift
//  ClientSocketProject
//
//  Created by Gilberto Magno on 15/05/25.
//

@globalActor
actor SocketActor: GlobalActor {
    static let shared = SocketActor()
    func run(_ completion: @escaping () -> Void) { completion() }
}
