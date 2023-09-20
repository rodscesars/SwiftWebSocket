//
//  WebSocketViewModel.swift
//  SwiftWebSocket
//
//  Created by Rodrigo Mendes on 06/09/23.
//

import Foundation
import WebRTC
import AVFoundation

class ViewModel: ObservableObject {

    @Published var webSocketManager: WebSocketManager?
    @Published var webRTC: WebRTCClient?
    @Published var users: [User] = []
    @Published var messages: [ChatMessage] = []
    @Published var conected = false
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var id: String = UUID().uuidString

    init() {
        webSocketManager = WebSocketManager()
        webRTC = WebRTCClient(iceServers: [])
        webSocketManager?.delegate = self
        webRTC?.delegate = self
    }

    func joinRoom() {
        webSocketManager?.joinRoom(username: username, password: password)
    }

    func sendMessage(message: String) {
        webSocketManager?.sendMessage(username: username, message: message, id: id)
    }

    func sendOffer() {
        
    }

//    func sendIce(candidate: RTCIceCandidate) {
//        self.webSocketManager.localIceCandidate(candidate)
//    }
}

extension ViewModel: WebSocketConnectionDelegate {
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
}

extension ViewModel: WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        print("discovered local candidate")
//        self.sendIce(candidate)
    }

    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        let text: String
        switch state {
            case .connected, .completed:
                text = "conectado"
            case .disconnected:
                text = "desconectado"
            case .failed, .closed:
                text = "falhou"
            case .new, .checking, .count:
                text = "novo"
            default:
                text = "error"
        }
        print(text)
    }
}


