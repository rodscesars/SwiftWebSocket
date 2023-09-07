//
//  WebSocketViewModel.swift
//  SwiftWebSocket
//
//  Created by Rodrigo Mendes on 06/09/23.
//

import Foundation

class WebSocketViewModel: ObservableObject, WebSocketConnectionDelegate {
    @Published var webSocketManager: WebSocketManager?
    @Published var users: [User] = []
    @Published var messages: [ChatMessage] = []
    @Published var conected = false
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var id: String = UUID().uuidString

    init() {
        webSocketManager = WebSocketManager()
        webSocketManager?.delegate = self
    }


    func onConnected(connection: WebSocketConnection) {
        print("Connected")
    }

    func onDisconnected(connection: WebSocketConnection, error: Error?) {
        if let error = error {
            print("Disconnected with error:\(error)")
        } else {
            print("Disconnected normally")
        }
    }

    func onError(connection: WebSocketConnection, error: Error) {
        print("Connection error:\(error)")
    }

    func onMessage(connection: WebSocketConnection, text: String) {
        print("Text message: \(text)")

        guard let data = text.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let type = jsonObject["type"] as? String else { return }

        switch type {
        case "ping":
            webSocketManager?.ping()

        case "user":
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            if let kind = jsonObject["kind"] as? String, kind == "delete", let username = jsonObject["username"] {
                DispatchQueue.main.async { [weak self] in
                    self?.users.removeAll(where: { user in
                        return user.username == username as! String
                    })
                }
            } else {
                do {
                    let user = try decoder.decode(User.self, from: data)

                    DispatchQueue.main.async { [weak self] in
                        self?.users.append(user)
                    }
                } catch {
                    print("Decoding error: \(error)")
                }
            }


        case "chathistory":
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let message = try decoder.decode(ChatMessage.self, from: data)

                DispatchQueue.main.async { [weak self] in
                    self?.messages.append(message)
                }
            } catch {
                print("Decoding error: \(error)")
            }
        case "chat":
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let message = try decoder.decode(ChatMessage.self, from: data)

                DispatchQueue.main.async { [weak self] in
                    self?.messages.append(message)
                }
            } catch {
                print("Decoding error: \(error)")
            }
        default:
            break
        }


    }

    func onMessage(connection: WebSocketConnection, data: Data) {
        print("Data message: \(data)")
    }

    func joinRoom() {
        webSocketManager?.joinRoom(username: username, password: password)
    }

    func sendMessage(message: String) {
        webSocketManager?.sendMessage(username: username, message: message, id: id)
    }

}
