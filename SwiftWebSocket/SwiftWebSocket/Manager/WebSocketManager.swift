//
//  WebSocketManager.swift
//  SwiftWebSocket
//
//  Created by Rodrigo Mendes on 06/09/23.
//

import Foundation
import WebRTC

protocol WebSocketConnection {
    func send(text: String)
    func send(data: Data)
    func connect(url: URL, id: String)
    func disconnect()
    var delegate: WebSocketConnectionDelegate? {
        get
        set
    }
}

protocol WebSocketConnectionDelegate {
    func onConnected(connection: WebSocketConnection)
    func onDisconnected(connection: WebSocketConnection, error: Error?)
    func onError(connection: WebSocketConnection, error: Error)
    func onMessage(connection: WebSocketConnection, text: String)
    func onMessage(connection: WebSocketConnection, data: Data)
}


class WebSocketManager: NSObject, WebSocketConnection {
    var delegate: WebSocketConnectionDelegate?
    var webSocketTask: URLSessionWebSocketTask!
    var urlSession: URLSession!
    let delegateQueue = OperationQueue()

    override init() {
        super.init()
    }

    func connect(url: URL, id: String) {
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: delegateQueue)
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask.resume()
        performHandshake(id: id)
        listen()
    }

    func disconnect() {
        webSocketTask.cancel(with: .goingAway, reason: nil)
    }

    func performHandshake(id: String) {
        let handshakeData: [String: Any] = ["type": "handshake", "version": ["2"], "id": id]

        let handshakeJson = try? JSONSerialization.data(withJSONObject: handshakeData)

        if let data = handshakeJson {
            self.send(data: data)
        }
    }

    func joinRoom(username: String, password: String ) {

        let joinData: [String: Any] = ["type":"join","kind":"join","group":"public","username":"\(username)","password":"\(password)"]

        let joinJson = try? JSONSerialization.data(withJSONObject: joinData)

        if let data = joinJson {
            self.send(data: data)
        }
    }

    func ping() {
        let pongData: [String: Any] = ["type":"pong"]

        let pongJson = try? JSONSerialization.data(withJSONObject: pongData)

        if let data = pongJson {
            self.send(data: data)
        }
    }

    func sendMessage(username: String, message: String, id: String) {
        let messageData: [String: Any] = ["type":"chat","source": id,"dest":"","username": username,"kind":"","value": message]

        let messageJson = try? JSONSerialization.data(withJSONObject: messageData)

        if let data = messageJson {
            self.send(data: data)
        }
    }

    func sendSdp(sdp: RTCSessionDescription, id: String, username: String, streamId: String) {

        let offerData: [String: Any?] = [    "type": "offer",
                                             "kind": "",
                                             "id": streamId,
                                             "label": "camera",
                                             "replace": nil,
                                             "source": id,
                                             "username": username,
                                             "sdp": sdp]

        let messageJson = try? JSONSerialization.data(withJSONObject: offerData)

        if let data = messageJson {
            self.send(data: data)
        }
    }

    func sendIce(candidate: RTCIceCandidate, streamId: String){

        let iceData: [String: Any?] = ["type":"ice",
                                      "id": streamId,
                                      "candidate":
                                        ["candidate": candidate.sdp,
                                         "sdpMid": candidate.sdpMid,
                                         "sdpMLineIndex": candidate.sdpMLineIndex,
                                         "usernameFragment": candidate.description] as [String : Any?]
        ]

        let messageJson = try? JSONSerialization.data(withJSONObject: iceData)

        if let data = messageJson {
            self.send(data: data)
        }
    }

    func listen()  {
        webSocketTask.receive { result in
            switch result {
            case .failure(let error):
                self.delegate?.onError(connection: self, error: error)
            case .success(let message):
                switch message {
                case .string(let text):
                    self.delegate?.onMessage(connection: self, text: text)
                case .data(let data):
                    self.delegate?.onMessage(connection: self, data: data)
                @unknown default:
                    fatalError()
                }
                self.listen()
            }
        }
    }

    func send(text: String) {
        webSocketTask.send(URLSessionWebSocketTask.Message.string(text)) { error in
            if let error = error {
                self.delegate?.onError(connection: self, error: error)
            }
        }
    }

    func send(data: Data) {
        webSocketTask.send(URLSessionWebSocketTask.Message.data(data)) { error in
            if let error = error {
                self.delegate?.onError(connection: self, error: error)
            }
        }
    }
}

extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        self.delegate?.onConnected(connection: self)
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        self.delegate?.onDisconnected(connection: self, error: nil)
    }
}
