//
//  VideoViewControllerWrapper.swift
//  SwiftWebSocket
//
//  Created by Rodrigo Mendes on 25/09/23.
//

import SwiftUI
import UIKit

struct VideoViewControllerWrapper: UIViewControllerRepresentable {
    let webRTCClient: WebRTCClient?

    func makeUIViewController(context: Context) -> VideoViewController {
        return VideoViewController(webRTCClient: webRTCClient ?? WebRTCClient(iceServers: []))
    }

    func updateUIViewController(_ uiViewController: VideoViewController, context: Context) {}
}
