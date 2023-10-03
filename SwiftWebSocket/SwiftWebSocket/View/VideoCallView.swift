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
    @State private var remoteVideoRenderers: [RTCVideoTrack] = []

    var body: some View {
        VStack(spacing: 10) {
            VideoView(videoTrack: viewModel.webRTC?.localVideoTrack).frame(width: 160, height: 160)

            ForEach(viewModel.webRTC?.remoteVideoTracks ?? [RTCVideoTrack](), id: \.self) { track in
                VideoView(videoTrack: track).frame(width: 160, height: 160)
            }
        }.onAppear {
            viewModel.webRTC?.startCaptureLocalVideo()
        }
    }
}

struct VideoView: UIViewRepresentable {
    let videoTrack: RTCVideoTrack?
    //    @Binding var refresh: Bool

    func makeUIView(context: Context) -> RTCMTLVideoView {
        let videoView = RTCMTLVideoView(frame: .zero)
        videoView.videoContentMode = .scaleAspectFill
        return videoView
    }

    func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {
        if ((videoTrack?.isEnabled) != nil) {
            videoTrack?.add(uiView)
        }
    }
}


#Preview {
    VideoCallView(viewModel: ViewModel())
}
