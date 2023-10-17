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
    var webSocketManager: WebSocketManager?
    @Published var users: [User] = []
    @Published var messages: [ChatMessage] = []
    @Published var conected = false
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var id: String = UUID().uuidString
    @Published var streamId: String = UUID().uuidString

    @Published var cameraPermissionGranted = false
    @Published var microphonePermissionGranted = false

    @Published var speakerOn: Bool = false
    @Published var mute: Bool = false
    @Published var hide: Bool = false

    var iceServerList: [RTCIceServer] = []

    @Published var upStream: [String : WebRTCClient] = [:]
    @Published var downStream: [String : WebRTCClient] = [:]

    var localVideoTrack: RTCVideoTrack? {
        upStream[streamId]?.localVideoTrack
    }

    var remoteVideoTracks: [RTCVideoTrack?] {
        downStream.map { key, value in
            return value.remoteVideoTrack
        }
    }

    init() {
        webSocketManager = WebSocketManager()
        webSocketManager?.delegate = self
    }

    func joinRoom() {
        webSocketManager?.joinRoom(username: username, password: password)
        webSocketManager?.sendRequest()
    }

    func sendMessage(message: String) {
        webSocketManager?.sendMessage(username: username, message: message, id: id)
    }

    func sendSession() {
        upStream[streamId]?.offer { sdp in
            self.webSocketManager?.sendOffer(sdp: sdp, userId: self.id, username: self.username, streamId: self.streamId)
        }
    }

    func endSession() {
        self.webSocketManager?.closeStream(streamId: streamId)
    }

    func sendIce(candidate: RTCIceCandidate, streamId: String) {
        self.webSocketManager?.sendIce(candidate: candidate, streamId: streamId)
    }

    func speaker() {
        if self.speakerOn {
            self.upStream.values.first!.speakerOff()
        }
        else {
            self.upStream.values.first!.speakerOn()
        }
        self.speakerOn = !self.speakerOn
    }

    func muteOn() {
        self.mute = !self.mute
        if self.mute {
            self.upStream.values.first!.muteAudio()
        }
        else {
            self.upStream.values.first!.unmuteAudio()
        }
    }

    func hideOn() {
        self.hide = !self.hide
        if self.hide {
            self.upStream.values.first!.hideVideo()
        }
        else {
            self.upStream.values.first!.showVideo()
        }
    }

    func sendRenegotiate(id: String) {
        webSocketManager?.sendRenegotiate(id: id)
    }
}

extension ViewModel: WebSocketConnectionDelegate {
    func onConnected(connection: WebSocketConnection) {
        print("Connected")
    }

    func onDisconnected(connection: WebSocketConnection, error: Error?) {
        if let error = error {
            print("Disconnected with error:\(error)")
            self.conected = false
        } else {
            print("Disconnected normally")
            self.conected = false
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

        case "joined":
            if let rtcConfiguration = jsonObject["rtcConfiguration"] as? [String: Any],
               let iceServers = rtcConfiguration["iceServers"] as? [[String: Any]] {


                for iceServerInfo in iceServers {
                    if let urls = iceServerInfo["urls"] as? [String],
                       let username = iceServerInfo["username"] as? String,
                       let credential = iceServerInfo["credential"] as? String {

                        let iceServer = RTCIceServer(urlStrings: urls, username: username, credential: credential)
                        iceServerList.append(iceServer)
                    }
                }

                let webRTC = WebRTCClient(iceServers: iceServerList, id: streamId)

                DispatchQueue.main.async { [weak self] in
                    self?.upStream[webRTC.id] = webRTC
                }
            }

        case "user":
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            if let kind = jsonObject["kind"] as? String, kind == "delete", let id = jsonObject["id"] {
                DispatchQueue.main.async { [weak self] in
                    self?.users.removeAll(where: { user in
                        return user.id == id as! String
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
            if let id = jsonObject["id"] as? String,
               let sdpString = jsonObject["sdp"] as? String {

                let sdp = RTCSessionDescription(type: .offer, sdp: sdpString)

                if (downStream[id] != nil) {
                    print("there is a peerconnection on the dict already")
                } else {
                    let webRTC = WebRTCClient(iceServers: iceServerList, id: id)
                    webRTC.delegate = self

                    DispatchQueue.main.async { [weak self] in
                        self?.downStream[id] = webRTC

                        self?.downStream[id]?.set(remoteSdp: sdp) { (error) in
                            print("Received remote sdp")
                        }

                        self?.downStream[id]?.answer(completion: { sdp in
                            self?.webSocketManager?.sendAnswer(sdp: sdp, streamId: id)
                        })
                    }
                }

            }

        case "answer":
            if let sdpString = jsonObject["sdp"] as? String,
               let id = jsonObject["id"] as? String {

                let sdp = RTCSessionDescription(type: .answer, sdp: sdpString)

                guard let peerConnection = upStream[id] else { return }

                peerConnection.set(remoteSdp: sdp) { error in
                    print("Received remote sdp")
                }
            }

        case "ice":
            if let candidateData = jsonObject["candidate"] as? [String: Any],
               let streamId = jsonObject["id"] as? String,
               let candidate = candidateData["candidate"] as? String,
               let sdpMLineIndex = candidateData["sdpMLineIndex"] as? Int32,
               let sdpMid = candidateData["sdpMid"] as? String {

                let iceCandidate = RTCIceCandidate(sdp: candidate, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)

                guard let peerConnection = downStream[streamId] else { return }

                peerConnection.set(remoteCandidate: iceCandidate) { error in
                    print("Recebeu um candidato remoto")
                }
            }

        case "close":
            if let id = jsonObject["id"] as? String {
                
                DispatchQueue.main.async { [weak self] in
                    self?.downStream.removeValue(forKey: id)
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
        print("gerou um ice candidate local")
        self.sendIce(candidate: candidate, streamId: client.id)
    }
}


