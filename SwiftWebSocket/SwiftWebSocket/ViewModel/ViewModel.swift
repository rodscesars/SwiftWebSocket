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
    @Published var streamId: String = UUID().uuidString
    @Published var text: String = ""

    @Published var hasRemoteSdp: Bool = false
    @Published var remoteCandidate: Bool = false

    @Published var cameraPermissionGranted = false
    @Published var microphonePermissionGranted = false

    @Published var speakerOn: Bool = false
    @Published var mute: Bool = false

    fileprivate let defaultIceServers = ["stun:stun.l.google.com:19302",
                                         "stun:stun1.l.google.com:19302",
                                         "stun:stun2.l.google.com:19302",
                                         "stun:stun3.l.google.com:19302",
                                         "stun:stun4.l.google.com:19302"]


    init() {
        webSocketManager = WebSocketManager()
        webRTC = WebRTCClient(iceServers: defaultIceServers)
        webSocketManager?.delegate = self
        webRTC?.delegate = self
    }

    func joinRoom() {
        webSocketManager?.joinRoom(username: username, password: password)
        webSocketManager?.sendRequest()
    }

    func sendMessage(message: String) {
        webSocketManager?.sendMessage(username: username, message: message, id: id)
    }

    func sendSession() {
        webRTC?.offer { (sdp) in
            self.webSocketManager?.sendSdp(sdp: sdp, id: self.id, username: self.username, streamId: self.id)
        }
    }

    func answerSession() {
        webRTC?.answer { (sdp) in
            self.webSocketManager?.sendSdp(sdp: sdp, id: self.id, username: self.username, streamId: self.streamId)
        }
    }

    func speaker() {
        if self.speakerOn {
            self.webRTC?.speakerOff()
        }
        else {
            self.webRTC?.speakerOn()
        }
        self.speakerOn = !self.speakerOn
    }

    func muteOn() {
        self.mute = !self.mute
        if self.mute {
            self.webRTC?.muteAudio()
        }
        else {
            self.webRTC?.unmuteAudio()
        }
    }

    func sendIce(candidate: RTCIceCandidate, streamId: String) {
        self.webSocketManager?.sendIce(candidate: candidate, streamId: streamId)
    }
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

        case "offer":
            if let sourceId = jsonObject["source"] as? String, sourceId != id {
                if let sdpString = jsonObject["sdp"] as? String {
                    let sdp = RTCSessionDescription(type: .offer, sdp: sdpString)

                    DispatchQueue.main.async { [weak self] in
                        self?.webRTC?.set(remoteSdp: sdp) { (error) in
                            print("Received remote sdp")
                        }
                    }
                }
            }

        case "ice":
            if let candidateData = jsonObject["candidate"] as? [String: Any],
               let candidate = candidateData["candidate"] as? String,
               let sdpMLineIndex = candidateData["sdpMLineIndex"] as? Int32,
               let sdpMid = candidateData["sdpMid"] as? String {

                let iceCandidate = RTCIceCandidate(sdp: candidate, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
                
                DispatchQueue.main.async { [weak self] in
                    self?.webRTC?.set(remoteCandidate: iceCandidate) { error in
                        print("Received remote candidate")
                    }
                }
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
        self.sendIce(candidate: candidate, streamId: self.streamId)
    }

    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
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
    }
}


