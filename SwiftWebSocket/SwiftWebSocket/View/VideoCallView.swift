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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        viewModel.sendSession()
                    }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 10))
                    }.disabled(true)

                    Button(action: {
                        viewModel.answerSession()
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 10))
                    }

                    Button(action: {
                        viewModel.speaker()
                    }) {
                        Image(systemName: viewModel.speakerOn ? "speaker.fill" : "speaker.slash.fill")
                            .font(.system(size: 10))
                    }

                    Button(action: {
                        viewModel.muteOn()
                    }) {
                        Image(systemName: viewModel.mute ? "mic.slash.fill" : "mic.fill")
                            .font(.system(size: 10))
                    }
                }
            }
        }
        .navigationTitle(viewModel.text)
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
