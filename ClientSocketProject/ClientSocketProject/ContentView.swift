//
//  ContentView.swift
//  ClientSocketProject
//
//  Created by Gilberto Magno on 12/05/25.
//

import SwiftUI

struct ConnectionRoomView: View {
    @State private var manager = ConnectionRoomManager.shared
    @State private var path: NavigationPath = .init()
#if os(macOS)
    @State private var window: NSWindow?
#endif
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                Text("Socket Room").font(.title)

                TextField("Port", value: $manager.port, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .disabled(manager.state != .offline)

                HStack {
                    Button("Create Room") {
                        manager.hostRoom()
                    }.disabled(manager.state != .offline)

                    Button("Join Room") {
                        manager.joinRoom()
                    }.disabled(manager.state != .offline)
                }

                Text("Status: \(String(describing: manager.state).capitalized)")
                    .padding(.top)

                ChatView()

                if manager.state == .connected {
                    if ConnectionRoomManager.playerNumber == 1 {
                        Button("Start Game") {
                            manager.sendMessage(type: .gameStart, content: "Start")
                            path.append("game")
                        }
                    } else {
                        Text("Await opponent to start the game...")
                    }
                }
            }
            .padding()
            .navigationDestination(for: String.self) { value in
                SeegaGameView()
            }
            .onAppear {
                manager.navigateToGame = {
                    path.append("game")
                }
            }
        }
#if os(macOS)
        .background(WindowAccessor(window: $window))
        .onChange(of: window) {
            window?.setFrame(NSRect(origin: .init(x: 410, y: 270) , size: .init(width: 514, height: 580)), display: true, animate: true)
        }
#endif
    }
}
