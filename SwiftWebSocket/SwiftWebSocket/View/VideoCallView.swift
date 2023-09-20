//
//  VideoCallView.swift
//  SwiftWebSocket
//
//  Created by Rodrigo Mendes on 20/09/23.
//

import SwiftUI
import WebRTC

struct VideoCallView: View {
    @ObservedObject var viewModel: ViewModel

    var localVideoTrack = RTCMTLVideoView()
    var remoteVideoTrack = RTCMTLVideoView()

    var body: some View {
        ZStack {
            VideoView(videoTrack: viewModel.webRTC?.remoteVideoTrack)
                .ignoresSafeArea()

            VideoView(videoTrack: viewModel.webRTC?.localVideoTrack)
                .frame(width: 120, height: 160)
                .position(x: UIScreen.main.bounds.width - 80, y: UIScreen.main.bounds.height - 120)
        }.onAppear {
            viewModel.webRTC?.startCaptureLocalVideo(renderer: localVideoTrack)
            viewModel.webRTC?.renderRemoteVideo(to: remoteVideoTrack)
        }
    }
}

struct VideoView: UIViewRepresentable {
    let videoTrack: RTCVideoTrack?

    func makeUIView(context: Context) -> RTCMTLVideoView {
        let videoView = RTCMTLVideoView(frame: .zero)
        videoView.videoContentMode = .scaleAspectFill
        videoTrack?.add(videoView)
        return videoView
    }

    func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {}
}

//#Preview {
//    VideoCallView()
//}
